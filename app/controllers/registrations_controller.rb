class RegistrationsController < ApplicationController
  def create
    @user = User.new(registration_params)
    if @user.save
      login @user
      render json: { message: "Registered successfully", user: @user, session: session }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end