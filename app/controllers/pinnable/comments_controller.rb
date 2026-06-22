module Pinnable
  class CommentsController < ApplicationController
    def create
      render json: { public_id: comment.public_id, author_label: comment.author_label, body: comment.body }, status: :created
    end

    private

    def comment
      @comment ||= AddComment.new(pin:, author: pinnable_user, params: comment_params).call
    end

    def pin = pinnable_pins.find_by!(public_id: params[:pin_public_id])
    def comment_params = params.require(:comment).permit(:body)
  end
end
