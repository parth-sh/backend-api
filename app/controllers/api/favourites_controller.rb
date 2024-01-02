class Api::FavouritesController < ApplicationController
  before_action :authenticate_user!

  def create
    favourite = Favourite.create(user_id: current_user.id, property_id: params[:property_id])
    render json: favourite
  end

  def destroy
    favourite = Favourite.find_by(user_id: current_user.id, property_id: params[:property_id])
    favourite.destroy!
    render status: :no_content
  end
end
