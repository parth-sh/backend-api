class ApplicationController < ActionController::API

  private

  def authenticate_user!
    render json: { errors: ["You must be logged in to do that"] },
           status: :unauthorized unless user_signed_in?
  end

  def require_sign_out!
    render json: { errors: ["You must be logged out to do that"] },
           status: :unauthorized if user_signed_in?
  end

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
