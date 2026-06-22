module Pinnable::Comment::Relationships
  extend ActiveSupport::Concern

  included do
    belongs_to :pin, class_name: "Pinnable::Pin", inverse_of: :comments
    belongs_to :author, polymorphic: true, optional: true
  end
end
