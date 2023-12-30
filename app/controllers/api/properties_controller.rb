class Api::PropertiesController < ApplicationController
  def show
    @property = Property.all
    render json: @property
  end
end