class Auth::SessionsController < ApplicationController
  def create
    if (user = User.authenticate_by(session_params))
      login user
      render json: { message: "Logged in successfully" }
    else
      render json: { errors: ["Invalid email or password"] }, status: :unprocessable_entity
    end
  end

  def destroy
    logout current_user
    render json: { message: "Logged out successfully" }
  end

  private

  def session_params
    params.require(:user).permit(:email, :password)
  end
end