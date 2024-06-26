class Api::PropertiesController < ApplicationController
  def show
    @properties = Property.all
    render json: @properties.as_json(methods: [:formatted_price, :default_image, :available_dates])
  end
end