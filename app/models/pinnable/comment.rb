module Pinnable
  class Comment < ApplicationRecord
    has_secure_token :public_id

    include Comment::Relationships
    include Comment::Validations
    include Comment::Encryption
  end
end
