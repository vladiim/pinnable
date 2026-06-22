module Pinnable::Pin::Encryption
  extend ActiveSupport::Concern

  # Opt-in: hosts set `config.encrypt = true` (and configure Active Record encryption).
  # Read at load — declared after `serialize :anchor`, so encryption wraps the JSON coder.
  included do
    encrypts :body, :anchor if Pinnable.config.encrypt
  end
end
