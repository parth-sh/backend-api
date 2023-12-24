This guide explores Rails 7.1's API-only authentication methods, covering user sessions, registration, login, and email verification. It delves into updating passwords and securely resetting forgotten ones via email. Additionally, it integrates these backend processes with the frontend user interface, ensuring a seamless and secure user experience.

It introduces new features such as authenticate_by, ActiveSupport::CurrentAttributes, has_secure_password, normalizes, password_challenge, generates_token_for, password_salt.

References taken from:

- [Rails Authentication from Scratch](https://stevepolito.design/blog/rails-authentication-from-scratch)
- [Rails 7.1 Authentication From Scratch](https://youtu.be/Hb9WtQf9K60)
- [Rails Guides: API App](https://guides.rubyonrails.org/api_app.html)
- [Mintbit: Rails Current Attributes - Usage, Pros and Cons](https://www.mintbit.com/blog/rails-current-attributes-usage-pros-and-cons)
- [Mintbit: Rails 7.1 Generate Tokens for Specific Purposes with generates_token_for](https://www.mintbit.com/blog/rails-7-dot-1-generate-tokens-for-specific-purposes-with-generates-token-for)

First, we need to create a backend API:
```sh
rails new backend-api -T -d postgresql --api
bin/rails db:create
bin/rake db:migrate
```

We will define our routes, which will be used for authentication:
```rb
# config/routes.rb
resource :registration
resource :session
resource :password_reset # Forgot password
resource :password # Update the password while logged in
```

Let's build our RegistrationsController:
```rb
# app/controller/registrations_controller.rb
class RegistrationsController < ApplicationController
  def create
    @user = User.new(registration_params)
    if @user.save
      login @user
      render json: { message: @user, session: session }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
```

Next, let's generate our User model:
```rb
rails g model User email password_digest
rails db:migrate
```
The password_digest column will store a hashed version of the user’s password.

Let's edit our User model:
```rb
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, presence: true, uniqueness: true
  normalizes :email, with: -> email { email.strip.downcase }
end
```
The has_secure_password method is added to give us an [API](https://api.rubyonrails.org/classes/ActiveModel/SecurePassword/ClassMethods.html#method-i-has_secure_password) to work with the password_digest column.
The 'validates :email' line ensures the email's presence, uniqueness, and proper format. The 'normalizes' method performs the intended operation on the field before saving it to the database.

Above, in the RegistrationsController, we used the 'login @user' method. Let's build that at a common place where we can use it further also:
```rb
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API

  private

  def login(user)
    Current.user = user
    reset_session
    session[:user_id] = user.id
  end
end
```

Current.user, used above, is for ActiveSupport::CurrentAttributes feature of Rails:
```rb
# app/model/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
```
This will be used to store the user as we process the request, and will automatically be cleared out with each new request. It works like a Singleton class, getting automatically cleared per request. It should not be used with background jobs. For more, see: [ActiveSupport::CurrentAttributes](https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html)

Let's add a few other useful methods to ApplicationController:
```rb
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API

  private

  def authenticate_user_from_session
    User.find_by(id: session[:user_id])
  end

  def current_user
    Current.user ||= authenticate_user_from_session
  end

  def user_signed_in?
    current_user.present?
  end

  def login(user)
    Current.user = user
    reset_session
    session[:user_id] = user.id
  end

  def logout(user)
    Current.user = nil
    reset_session
  end
end
```

Now, try to run the server (I have chosen port 8080) and hit the API.

You may face an error while sending the API request:
```sh
ActionDispatch::Request::Session::DisabledSessionError (Your application has sessions disabled. To write to the session you must first configure a session store):
```
This is because, by default, session store is disabled in Rails API-only apps. So, go ahead and add a session store for your Rails API-only app:
```rb
# config/application.rb
config.session_store :cookie_store, key: '_interslice_session'
config.middleware.use ActionDispatch::Cookies
config.middleware.use config.session_store, config.session_options
```

Let's test out the registrations#create API:
```json
# http://localhost:8080/registration
{
    "user": {
        "email": "parth10@gmail.com",
        "password": "password",
        "password_confirmation": "password"
    }
}
```
Response:
```json
{
    "user": {
        "id": 1,
        "email": "parth@gmail.com",
        "password_digest": "$2a$12$vAm8SrZAkvQndW9wugHzfepKDQbbo/3M2A6I8h0viYqvRhWinAuMK",
        "created_at": "2023-12-21T13:45:16.906Z",
        "updated_at": "2023-12-21T13:45:16.906Z"
    },
    "session": {
        "session_id": "c6ccfcdce8698d76381cd22ac9c60516",
        "user_id": 1
    }
}
```

Now, let's create our logout method. For this, we will add our code in sessions_controller.rb:
```rb
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  def destroy
    logout current_user
    render json: "Logged out successfully", status: :ok
  end
end
```

Let's test out the sessions#destroy API:
```json
# DELETE http://localhost:8080/session
```
Response:
```json
{
    "message": "Logged out successfully",
    "session": {
        "session_id": "262022c6a997d69109728331d4551465"
    }
}
```

For the login method:
```rb
# app/controllers/sessions_controller.rb
def create
  if (user = User.authenticate_by(session_params))
    login user
    render json: { message: "Logged in successfully", user: user, session: session }
  else
    render json: { errors: ["Invalid email or password"] }, status: :unprocessable_entity
  end
end

private

def session_params
  params.permit(:email, :password)
end
```

Let's test the sessions#create API:
```json
POST http://localhost:8080/session
{
    "email": "parth10@gmail.com",
    "password": "password3"
}
```
Response:
```json
{
    "message": "Logged in successfully",
    "user": {
        "id": 2,
        "email": "parth10@gmail.com",
        "password_digest": "$2a$12$9J5IyW4nWDfDHGNFAhiGFu79CV3oAYl6wic3dGTiFDXAIYpZuQq5i",
        "created_at": "2023-12-20T13:45:16.906Z",
        "updated_at": "2023-12-21T14:39:02.690Z"
    },
    "session": {
        "session_id": "1f1cc263a9a4d738b29521bbfb7f07a8",
        "user_id": 2
    }
}
```

Next, let's address editing the password. For this, we will create a passwords_controller, but before that, let's create a helper method authenticate_user!, which will prevent us from using the API if the user is not logged in:
```rb
# app/controllers/application_controller.rb
def authenticate_user!
    render json: { message: "You must be logged in to do that", user: current_user, session: session },
           status: :unauthorized unless user_signed_in?
  end
```

In passwords_controller.rb:
```rb
# app/controllers/passwords_controller.rb
  def update
    if current_user.update(password_params)
      render json: { message: "Your password has been updated successfully", user: current_user, session: session }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation, :password_challenge)
          .with_defaults(password_challenge: "")
  end
```

A new feature we have is the password_challenge in has_secure_password, so it will define these virtual attributes and if you have a password_challenge submitted it's going to make sure that matches the current password in the database, that way you can verify the current password before you change the password to a new one. In order to evade this, a user can simply delete the password_challenge field out of the HTML and only submit password, password_confirmation and if you skip that, this password_challenge would be nil and it will skip that confirmation, so the way we can do that is we use with_defaults(password_challenge: "") and as long as this is not nil then it will go ahead and verify the current password. That's a small adjustment you can make to your password controller to use that new validation feature.


Let's try out the passwords#update API:
```json
PUT http://localhost:8080/password
{
    "user": {
        "password": "password2",
        "password_confirmation": "password2",
        "password_challenge": "password"
    }
}
```
Response:
```json
{
    "message": "Your password has been updated successfully",
    "user": {
        "password_digest": "$2a$12$IOCqAaHH1/uALUPsY5uFLex2ImC9vA17l.HbNgKeLngM74rPBb0mi",
        "email": "parth@gmail.com",
        "id": 1,
        "created_at": "2023-12-21T13:45:16.906Z",
        "updated_at": "2023-12-21T14:42:18.878Z"
    },
    "session": {
        "session_id": "1f1cc263a9a4d738b29521bbfb7f07a8",
        "user_id": 1
    }
}
```
Error Response:
```json
{
    "errors": [
        "Password challenge is invalid"
    ]
}
```

Now let's generate our forgot password, password reset flow, which will use the latest feature from rails 7.1 generates_token_for and this method will allow generating tokens that don't have to be stored in our database and also one-time use, so if we do
```rb
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true, uniqueness: true
  normalizes :email, with: -> email { email.strip.downcase }

  generates_token_for :password_reset, expires_in: 15.minutes do
    # `password_salt` (defined by `has_secure_password`) returns the salt for
    # the password. The salt changes when the password is changed, so the token
    # will expire when the password is changed.
    password_salt&.last(10)
  end

  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end
end
```

We can use this token similar to a signed global id "signed_id", in signed_id there is no way to revoke that token which is not good, that token can be used to reset the password anytime.

We are going to send this token out with an email.

For that, first, we need our password_resets_controller.rb
```rb
# app/controllers/password_resets_controller.rb
class PasswordResetsController < ApplicationController
  before_action :require_sign_out!
  before_action :set_user_by_token, only: [:update]

  def create
    if (user = User.find_by_email(params[:email]))
      PasswordMailer.with(
        user: user,
        token: user.generate_token_for(:password_reset)
      ).password_reset.deliver_later
    end

    render json: { message: "Check your email to reset your password", user: user, session: session }
  end

  def update
    if @user.update(password_params)
      render json: { message: "Password updated, please login", user: @user, session: session }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    render json: { errors: ["Invalid user token, please start over"] }, status: :unauthorized unless @user.present?
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
```

Here we have used "before_action :require_sign_out!" for stopping the user from accessing the API if logged in.
```rb
# app/ccontrollers/application_controller.rb
private 

def require_sign_out!
  render json: { message: "You must be logged out to do that", user: current_user, session: session },
           status: :unauthorized if user_signed_in?
end
```

For sending the email we will be generating our mailer
```rb
rails g mailer Password
```
This generated the password_mailer.rb and views let's edit the files.
```rb
class PasswordMailer < ApplicationMailer
  def password_reset
    mail to: params[:user].email
  end
end
```

And in views create a new file, password_reset.html.erb
```rb
# app/views/password_mailer/password_reset.html.erb
<%= link_to "Reset your password", "https://localhost:3000/edit_password_reset_url?token=#{params[:token]}" %>
```

This file will be sent via the mailer.

In PasswordMailer we are using user.generate_token_for(:password_reset) which we defined earlier in User.rb, this method will generate a unique token for the user, which will be sent via the email, and in that email after clicking the form a request will be sent to password_resets#update which will get token in params, which is being used in set_user_by_token by User.find_by_token_for and the newly updated password which will be updated.

These both methods are a part of ActiveRecord please, check this for an example: [Rails 7.1 Generate Tokens for Specific Purposes with generates_token_for](https://www.mintbit.com/blog/rails-7-dot-1-generate-tokens-for-specific-purposes-with-generates-token-for
)

Now let's test our password_resets#create API:
```json
# POST http://localhost:8080/password_reset
{
    "email": "parth10@gmail.com"
}
```
Response:
```json
{
    "message": "Check your email to reset your password",
    "user": {
        "id": 2,
        "email": "parth10@gmail.com",
        "password_digest": "$2a$12$GjHHiIK2dDJK31xfVL.81OF9VK7bZTT4uUfGYqYN/RHRK4uMrQaQ.",
        "created_at": "2023-12-20T13:45:16.906Z",
        "updated_at": "2023-12-21T16:05:25.648Z"
    },
    "session": {
        "session_id": "34dd3643ef156834698b9392c209eb1a"
    }
}
```
Email:
```shell
From: from@example.com
To: parth10@gmail.com
Message-ID: <658493e78c887_15fa4bdc9783c@mac1.local.mail>
Subject: Password reset
Mime-Version: 1.0
Content-Type: text/html;
 charset=UTF-8
Content-Transfer-Encoding: 7bit

<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      /* Email styles need to be inline */
    </style>
  </head>

  <body>
    <a href="https://localhost:3000/edit_password_reset_url?token=eyJfcmFpbHMiOnsiZGF0YSI6WzIsIjMxeGZWTC44MU8iXSwiZXhwIjoiMjAyMy0xMi0yMVQxOTo1MjoxMS41NTdaIiwicHVyIjoiVXNlclxucGFzc3dvcmRfcmVzZXRcbjkwMCJ9fQ==--5503e88776ef18386d16d6a9361ffc121ac4304c">Reset your password</a>
  </body>
</html>

[ActiveJob] [ActionMailer::MailDeliveryJob] [c8f6de52-7893-40d1-bbeb-a2c0510e68f6] Performed ActionMailer::MailDeliveryJob (Job ID: c8f6de52-7893-40d1-bbeb-a2c0510e68f6) from Async(default) in 19.46ms
```

Let's test our password_resets#update API:
```json
# PUT http://localhost:8080/password_reset
{
    "token": "eyJfcmFpbHMiOnsiZGF0YSI6WzIsIjMxeGZWTC44MU8iXSwiZXhwIjoiMjAyMy0xMi0yMVQxOTo1MjoxMS41NTdaIiwicHVyIjoiVXNlclxucGFzc3dvcmRfcmVzZXRcbjkwMCJ9fQ==--5503e88776ef18386d16d6a9361ffc121ac4304c",
    "user": {
        "password": "password3",
        "password_confirmation": "password3"
    }
}
```
Response:
```json
{
    "message": "Password has been reset successfully, Please login",
    "user": {
        "password_digest": "$2a$12$So.uFgT6MCGMI2ymq3PCK.Mp4qulObZFXh6Bj0hkS1HqlPgogCY6W",
        "email": "parth10@gmail.com",
        "id": 2,
        "created_at": "2023-12-20T13:45:16.906Z",
        "updated_at": "2023-12-21T19:41:14.348Z"
    },
    "session": {
        "session_id": "34dd3643ef156834698b9392c209eb1a"
    }
}
```

Now, let's add email confirmation for our users. When a user registers, we will send them an email to confirm their account.

First, we need to add a column to our user model:
```rb
rails g migration add_confirmation_column_to_users confirmed_at:datetime
rails db:migrate
```

In our User model, let's create a token for email confirmation:
```rb
# app/models/user.rb
generates_token_for :email_confirmation, expires_in: 24.hours do
  email + confirmed_at.to_s
end
```

Here, we've used the combination of 'email' and 'confirmed_at' to create the token. This ensures that once the email is verified and the 'confirmed_at' column in the user's record is updated, the previous token becomes unusable for further authentication.


Let's create a method to confirm the email in our registrations_controller.rb:
```rb
# app/controller/registrations_controller.rb
def confirm_email
  if @user.update(confirmed_at: Time.current)
    render json: { message: "Your email has been successfully confirmed. Please proceed to log in", user: @user, session: session }
  else
    render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
  end
end

private

def set_user_by_token
  @user = User.find_by_token_for(:email_confirmation, params[:token])
  render json: { errors: ["Invalid user token, Please try again"] }, status: :unauthorized unless @user.present?
end
```

Similar to password_reset, we need to create a mailer to send an email:
```rb
rails g mailer User   
```

Let's define a method to send an email:
```rb
# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def email_confirmation
    mail to: params[:user].email
  end
end
```

And in our views, we will create a mail:
```erb
# app/views/user_mailer/email_confirmation.html.erb
<%= link_to "Click here to confirm your email.", confirm_email_registration_url(token: params[:token]) %>
```

Let's conduct API testing for registrations#create and registrations#confirm_email. We'll initiate a POST request for user registration and then test the email confirmation through a GET request. The provided JSON snippets demonstrate the expected request format and the anticipated responses, including user details and session information. The email section shows the simulated confirmation email sent to the user.
```json
# POST http://localhost:8080/registration
{
    "user": {
        "email": "parth5@gmail.com",
        "password": "password",
        "password_confirmation": "password"
    }
}
```
Response:
```json
{
    "message": "Registration successful! Please check your email to confirm your account",
    "user": {
        "id": 10,
        "email": "parth5@gmail.com",
        "password_digest": "$2a$12$YgsfFEkzoVTJj3sHsZNxleosiGGBxxaarOxD1oeV/.hpjwtZj.7S.",
        "created_at": "2023-12-22T18:42:33.645Z",
        "updated_at": "2023-12-22T18:42:33.645Z",
        "confirmed_at": null
    },
    "session": {
        "session_id": "1edb35d5b4439167f72f90de928404c0",
        "user_id": 10
    }
}
```
Email:
```shell
[ActiveJob] [ActionMailer::MailDeliveryJob] [3f9d9aaa-9cee-4fd5-9d48-0eb7b4524f48] Date: Sat, 23 Dec 2023 00:12:33 +0530
From: from@example.com
To: parth5@gmail.com
Message-ID: <6585d899a67b4_340f481c276a9@mac1.local.mail>
Subject: Email confirmation
Mime-Version: 1.0
Content-Type: text/html;
 charset=UTF-8
Content-Transfer-Encoding: 7bit

<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <style>
      /* Email styles need to be inline */
    </style>
  </head>

  <body>
    <a href="http://localhost:8080/registration/confirm_email?token=eyJfcmFpbHMiOnsiZGF0YSI6WzEwLCJwYXJ0aDVAZ21haWwuY29tIl0sImV4cCI6IjIwMjMtMTItMjNUMTg6NDI6MzMuNjY1WiIsInB1ciI6IlVzZXJcbmVtYWlsX2NvbmZpcm1hdGlvblxuODY0MDAifX0%3D--b51fb9250c6883f1c1294b7d322774f9573edd02">Click here to confirm your email.</a>
  </body>
</html>

[ActiveJob] [ActionMailer::MailDeliveryJob] [3f9d9aaa-9cee-4fd5-9d48-0eb7b4524f48] Performed ActionMailer::MailDeliveryJob (Job ID: 3f9d9aaa-9cee-4fd5-9d48-0eb7b4524f48) from Async(default) in 14.33ms
```

registrations#confirm_email
```json
GET http://localhost:8080/registration/confirm_email?token=eyJfcmFpbHMiOnsiZGF0YSI6WzEwLCJwYXJ0aDVAZ21haWwuY29tIl0sImV4cCI6IjIwMjMtMTItMjNUMTg6NDI6MzMuNjY1WiIsInB1ciI6IlVzZXJcbmVtYWlsX2NvbmZpcm1hdGlvblxuODY0MDAifX0%3D--b51fb9250c6883f1c1294b7d322774f9573edd02
```
Response:
```json
{
    "message": "Your email has been successfully confirmed. Please proceed to log in",
    "user": {
        "confirmed_at": "2023-12-22T18:44:07.267Z",
        "email": "parth5@gmail.com",
        "id": 10,
        "password_digest": "$2a$12$YgsfFEkzoVTJj3sHsZNxleosiGGBxxaarOxD1oeV/.hpjwtZj.7S.",
        "created_at": "2023-12-22T18:42:33.645Z",
        "updated_at": "2023-12-22T18:44:07.273Z"
    },
    "session": {
        "session_id": "1edb35d5b4439167f72f90de928404c0",
        "user_id": 10
    }
}
```

---

## Frontend Integration

We're integrating our API with the frontend app. First, we'll address CORS errors by enabling the rack-cors gem in our Rails Gemfile and configuring CORS in config/initializers/cors.rb.

```rb
# Gemfile
gem "rack-cors"
```
```rb
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000"

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```


Next, we'll create an API to locate users by email. If the user exists in the database, we'll redirect them to the login page. If the user does not exist, we'll direct them to the signup page.

```rb
# app/controllers/api/users_controller.rb
class Api::UsersController < ApplicationController
  def find_by_email
    user = User.find_by(email: params[:email])
    if user
      render json: user
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end
end
```
```rb
# config/routes.rb
namespace :api do
  resources :users, only: [] do
    collection do
      get :find_by_email
    end
  end
end
```

To include session cookies in each request, axios with withCredentials: true has been set in the Next.js framework:
```js
const api = axios.create({
    baseURL: process.env.NEXT_PUBLIC_API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
    withCredentials: true // to access session cookies
});
```

This ensures the _interslice_session cookie is set whenever it's included in the response header.

You might encounter an error stating, "Value of 'Access-Control-Allow-Credentials' header in response is '' which must be 'true'." To resolve this, I've included credentials: true in config/cors.rb:
```rb
# config/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000"

    resource "*",
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: true # Access-Control-Allow-Credentials' header in the response is '' which must be 'true'
  end
end
```
This adjustment ensures proper handling of the 'Access-Control-Allow-Credentials' header.



This blog's got its heart in the backend jungle 🌴, so I'm skipping the frontend safari here! For those adventurous souls eager to explore the frontend wilderness, fear not! Your map awaits at: 🗺️

[Student Accommodation Portal on GitHub](https://github.com/parth-sh/Student-Accommodation-Portal) 🚀 Happy coding!

![mainpage1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/txszy0amqzjt5l0auie9.png)

![usercheck1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7munvdcb1bd6p6f005vc.png)

![signup1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ggmv3rk3nfu5or28dx91.png)

![signup2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/u6rozzn3s2gokr27ecms.png)

![signup3](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0dbk2u81vcel4y7rfi7e.png)

Extensively utilized ChatGPT for crafting registration and login screens, and customizing Tailwind CSS.

![chatgptloginpage1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/vkbzt31xq4wbx81rdvcn.png)

![chatgptloginpage2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/tju99an4frlnpdqwfctt.png)

![chatgptloginpage3](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wadjtafe76iahlu4jqh5.png)

![chatgptloginpage4](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/sexwangk92j3cnruep8r.png)

![loginpage1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/v6erjgcg13ejn5x806gd.png)

![logout](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/sclj4crdgsakxva44ex9.png)

Implemented the "forgot password" feature in the frontend using ChatGPT, which significantly simplified the process.

![chatgptforgotpass1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/h0tnrg5m2rolqwd9c7sr.png)

![chatgptforgotpass2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/6lm22fj3d6l2pi39c9oq.png)

![chatgptforgotpass3](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/cj2pd7dniyl8qwn9fnnm.png)

![forgotpass1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/myj144ti78lrzgafrlrv.png)

![forgotpass2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/jvqx10az8nnpphgwn30z.png)

![forgotpass3](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/b52pm90o906cqywgcw4z.png)

![forgotpass4](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/j953au6lf7q31vjrsbql.png)

Designed "update password" screens using ChatGPT.

![chatgptupdatepass1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/s02gzrur0v6efo0ysuwp.png)

![chatgptupdatepass2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/v2553ffhm2nla1ryeorg.png)

![chatgptupdatepass3](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/7dn25l1ap4c84xqfs2el.png)

![updatepass1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/m899j15jfnwie4fmzi0u.png)

![updatepass2](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/d6bw2l1slzoin64gqbfn.png)
