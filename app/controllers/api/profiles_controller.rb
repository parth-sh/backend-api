class Api::ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:show, :update]

  def show
    render json: @profile.to_json(:except => [:id, :user_id, :created_at, :updated_at])
  end

  def update
    if @profile.update(profile_params)
      render json: @profile
    else
      render json: { errors: @profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_user.profile
  end

  def profile_params
    params.require(:profile).permit(:address_1, :address_2, :city, :state, :zip_code, :country)
  end
end
