class Task < ApplicationRecord
  belongs_to :customer
  belongs_to :carrier
  has_many :payments_tasks
  has_many :payments, through: :payments_tasks
  has_one :cost_calc
  has_many :remarks

  # Define failure_code enum (positional syntax)
  enum :failure_code, { no_failure: 0, address_not_found: 1, recipient_unavailable: 2, package_damaged: 3, refused_delivery: 4 }, prefix: true

  # Define status enum (positional syntax)
  enum :status, { pending: 0, in_transit: 1, delivered: 2, failed: 3, returned: 4 }

  validates :package_type, presence: true
  validates :start, presence: true
  validates :target, presence: true
  validates :delivery_time, presence: true
  validates :status, presence: true
  validates :barcode, presence: true, uniqueness: true
  validates :filled_form_url, allow_nil: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  # Turbo Streams: broadcast task list updates
  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_destroyed

  private

  def broadcast_created
    ApplicationController.renderer # ensure renderer is loaded
    broadcast_prepend_later_to "tasks", target: "tasks", partial: "tasks/task", locals: { task: self }
  end

  def broadcast_updated
    broadcast_replace_later_to "tasks", target: ActionView::RecordIdentifier.dom_id(self), partial: "tasks/task", locals: { task: self }
  end

  def broadcast_destroyed
    broadcast_remove_to "tasks", target: ActionView::RecordIdentifier.dom_id(self)
  end
end
