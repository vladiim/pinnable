module Pinnable
  # Appends a reply to a pin, stamping the author's display label like CapturePin does.
  class AddComment
    def initialize(pin:, author:, params:)
      @pin = pin
      @author = author
      @params = params
    end

    def call
      pin.comments.create!(
        author:,
        author_label: Pinnable.config.user_label.call(author),
        body: params[:body]
      )
    end

    private

    attr_reader :pin, :author, :params
  end
end
