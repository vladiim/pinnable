module Pinnable::Pin::Transitions
  extend ActiveSupport::Concern

  included do
    enum :status, { open: 0, resolved: 1, wont_fix: 2 }, default: :open
  end
end
