module Pinnable::Pin::Validations
  extend ActiveSupport::Concern

  included do
    validates :url, presence: true
    validates :body, presence: true
    validate :anchor_within_limit
  end

  private

  def anchor_within_limit
    return if anchor.to_json.bytesize <= Pinnable.config.anchor_max_bytes

    errors.add(:anchor, "is too large")
  end
end
