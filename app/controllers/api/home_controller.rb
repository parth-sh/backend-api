class Api::HomeController < ApplicationController
  def index
    @property = Property.all
    render json: @property
  end
end