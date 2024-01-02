class Api::PropertiesController < ApplicationController
  def show
    @properties = Property.all
    render json: @properties.as_json(methods: [:formatted_price, :default_image])
  end
end