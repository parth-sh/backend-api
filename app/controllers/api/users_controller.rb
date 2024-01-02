class Api::UsersController < ApplicationController
  before_action :authenticate_user!, only: [:favourite_properties]
  def find_by_email
    reset_session
    user = User.find_by(email: params[:email])
    if user
      render json: user
    else
      render json: { errors: ['User not found'] }, status: :not_found
    end
  end

  def favourite_properties
    render json: current_user.favourite_properties.pluck(:id)
  end
end
