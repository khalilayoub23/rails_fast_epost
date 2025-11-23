class AddAverageOverallRatingToCarriers < ActiveRecord::Migration[8.0]
  def change
    add_column :carriers, :average_overall_rating, :decimal, precision: 4, scale: 2, default: 0, null: false
  end
end
