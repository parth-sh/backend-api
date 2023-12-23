class Api::UsersController < ApplicationController
  def find_by_email
    reset_session
    user = User.find_by(email: params[:email])
    if user
      render json: user
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end
end
