class PaymentsTask < ApplicationRecord
  belongs_to :task
  belongs_to :payment
end
