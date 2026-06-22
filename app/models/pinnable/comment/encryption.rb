module Pinnable::Comment::Encryption
  extend ActiveSupport::Concern

  # Same opt-in as Pin — a reply can quote PII too.
  included do
    encrypts :body if Pinnable.config.encrypt
  end
end
