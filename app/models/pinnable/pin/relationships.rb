module Pinnable::Pin::Relationships
  extend ActiveSupport::Concern

  included do
    belongs_to :author, polymorphic: true, optional: true
    belongs_to :tenant, polymorphic: true, optional: true
    belongs_to :resolved_by, polymorphic: true, optional: true
    has_many :comments, class_name: "Pinnable::Comment", dependent: :destroy, inverse_of: :pin
  end
end
