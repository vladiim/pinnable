module Pinnable::Pin::Scopes
  extend ActiveSupport::Concern

  included do
    scope :for_url, ->(url) { where(url:) }
    scope :recent, -> { order(created_at: :desc) }
  end
end
