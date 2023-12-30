class Api::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: current_user.profile.to_json(:except => [:id, :user_id, :created_at, :updated_at])
  end
end