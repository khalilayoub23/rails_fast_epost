class AddSenderAndRecipientScoresToCarrierRatings < ActiveRecord::Migration[8.0]
  def change
    rename_column :carrier_ratings, :service_score, :recipient_score
    add_column :carrier_ratings, :sender_score, :integer, null: false, default: 3
  end
end
