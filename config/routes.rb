Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  namespace :auth do
    resource :registration, only: [:create] do
      collection do
        get 'confirm_email'
      end
    end
    resource :session, only: [:create, :destroy]
    resource :password_reset, only: [:create, :update] # Forgot password
    resource :password, only: [:update] # Update the password while logged in
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: proc { [404, {}, []] }

  namespace :api do
    resources :users, only: [] do
      collection do
        get :find_by_email
      end
    end
  end
end
