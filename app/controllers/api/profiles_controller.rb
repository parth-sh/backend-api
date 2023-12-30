class Api::ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: current_user.profile
  end
end