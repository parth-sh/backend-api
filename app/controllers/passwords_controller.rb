class PasswordsController < ApplicationController
  before_action :authenticate_user!

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
end