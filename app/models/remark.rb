class Remark < ApplicationRecord
  belongs_to :task
  belongs_to :remarkable, polymorphic: true
end
