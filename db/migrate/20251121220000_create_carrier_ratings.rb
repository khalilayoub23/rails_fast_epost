class CreateCarrierRatings < ActiveRecord::Migration[8.0]
  def change
    create_table :carrier_ratings do |t|
      t.references :carrier, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true, index: { unique: true }
      t.integer :completion_score, null: false
      t.integer :recipient_score, null: false
      t.string :rated_by
      t.text :comment
      t.timestamps
    end

    change_table :carriers, bulk: true do |t|
      t.decimal :average_completion_rating, precision: 4, scale: 2, default: 0, null: false
      t.decimal :average_service_rating, precision: 4, scale: 2, default: 0, null: false
      t.integer :ratings_count, default: 0, null: false
    end
  end
end
