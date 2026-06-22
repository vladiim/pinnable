module Pinnable
  class PinsController < ApplicationController
    def index
      @pins = pinnable_pins.recent
    end

    def show
      redirect_to "#{pin.url}?pinnable=#{pin.public_id}"
    end

    def create
      render json: { public_id: captured_pin.public_id }, status: :created
    end

    def update
      ResolvePin.new(pin:, by: pinnable_user, status: status_param).call
      respond_to do |format|
        format.json { head :no_content }                                  # the on-page widget
        format.html { redirect_to pins_path, notice: "Feedback updated." } # the inbox
      end
    end

    private

    def captured_pin
      @captured_pin ||= CapturePin.new(author: pinnable_user, tenant: pinnable_tenant, params: pin_params).call
    end

    def pin = @pin ||= pinnable_pins.find_by!(public_id: params[:public_id])

    def pin_params = params.require(:pin).permit(:url, :body, anchor: {})
    def status_param = params.require(:pin).permit(:status).fetch(:status)
  end
end
