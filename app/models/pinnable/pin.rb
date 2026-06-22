module Pinnable
  class Pin < ApplicationRecord
    has_secure_token :public_id
    serialize :anchor, coder: JSON, type: Hash

    include Pin::Relationships
    include Pin::Validations
    include Pin::Scopes
    include Pin::Transitions
    include Pin::Encryption
  end
end
