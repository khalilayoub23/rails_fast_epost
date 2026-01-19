class Cart < ApplicationRecord
  belongs_to :user

  has_many :cart_items, dependent: :destroy
  has_many :tasks, through: :cart_items

  def self.for(user)
    find_or_create_by!(user: user)
  end

  def add_task!(task)
    cart_items.find_or_create_by!(task: task)
  end

  def remove_task!(task)
    cart_items.where(task: task).destroy_all
  end
end
