class CreateNotificationPreferencesAndLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :notification_preferences do |t|
      t.string :notifiable_type, null: false
      t.bigint :notifiable_id, null: false
      t.integer :channel, null: false, default: 0
      t.boolean :enabled, null: false, default: true
      t.integer :quiet_hours_start
      t.integer :quiet_hours_end
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :notification_preferences, [ :notifiable_type, :notifiable_id, :channel ], name: "index_notification_preferences_on_notifiable_and_channel"

    create_table :notification_logs do |t|
      t.string :notifiable_type
      t.bigint :notifiable_id
      t.integer :channel, null: false
      t.string :message_type, null: false
      t.string :status, null: false, default: "sent"
      t.string :provider_message_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :sent_at

      t.timestamps
    end

    add_index :notification_logs, [ :notifiable_type, :notifiable_id ]
    add_index :notification_logs, :channel
    add_index :notification_logs, :status
    add_index :notification_logs, :message_type
  end
end
