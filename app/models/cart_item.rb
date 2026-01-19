class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :task

  validates :task_id, uniqueness: { scope: :cart_id }
end
