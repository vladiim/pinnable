module Pinnable
  # The wire shape the in-page overlay reads: enough to re-anchor (anchor blob) and to
  # show the note, never the host's User object — only its captured label.
  class MarkerSerializer
    def initialize(pin) = @pin = pin

    def call
      {
        public_id: pin.public_id,
        url: pin.url,
        body: pin.body,
        status: pin.status,
        author_label: pin.author_label,
        anchor: pin.anchor,
        comments: comments
      }
    end

    private

    attr_reader :pin

    def comments
      pin.comments.order(:created_at).map { |c| { author_label: c.author_label, body: c.body } }
    end
  end
end
