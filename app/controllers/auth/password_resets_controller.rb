class Auth::PasswordResetsController < ApplicationController
  before_action :require_sign_out!
  before_action :set_user_by_token, only: [:update]

  def create
    if (user = User.find_by_email(params[:email]))
      UserMailer.with(
        user: user,
        token: user.generate_token_for(:password_reset)
      ).password_reset.deliver_later
    end

    render json: { message: "Check your email to reset your password" }
  end

  def update
    if @user.update(password_params)
      render json: { message: "Password has been reset successfully, Please login" }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    render json: { errors: ["Invalid user token, Please try again"] }, status: :unauthorized unless @user.present?
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end