class SignatureEvent < ApplicationRecord
  belongs_to :delivery
  belongs_to :user

  enum :action, {
    signature_added: 0,
    pdf_generated: 1,
    delivery_completed: 2
  }

  validates :role, presence: true

  before_update :prevent_mutation
  before_destroy :prevent_mutation

  private

  def prevent_mutation
    raise ActiveRecord::ReadOnlyRecord, "Signature events are immutable" if persisted?
  end
end
