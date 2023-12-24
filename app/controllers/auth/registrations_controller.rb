class Auth::RegistrationsController < ApplicationController
  before_action :set_user_by_token, only: [:confirm_email]

  def create
    user = User.new(registration_params)
    if user.save
      login user
      UserMailer.with(
        user: user,
        token: user.generate_token_for(:email_confirmation)
      ).email_confirmation.deliver_later
      render json: { message: "Registration successful! Please check your email to confirm your account" }
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def confirm_email
    if @user.update(confirmed_at: Time.current)
      render json: { message: "Your email has been successfully confirmed. Please proceed to log in" }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for(:email_confirmation, params[:token])
    render json: { errors: ["Invalid user token, Please try again"] }, status: :unauthorized unless @user.present?
  end

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end