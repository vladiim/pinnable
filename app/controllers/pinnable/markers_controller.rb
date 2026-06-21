module Pinnable
  class MarkersController < ApplicationController
    def index
      render json: markers
    end

    private

    def markers = pins.map { |pin| MarkerSerializer.new(pin).call }
    def pins = pinnable_pins.for_url(params[:url]).open.recent
  end
end
