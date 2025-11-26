# frozen_string_literal: true

class CreateTrackingEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :tracking_events do |t|
      t.references :task, null: false, foreign_key: { on_delete: :cascade }
      t.string :event_type, null: false
      t.string :title, null: false
      t.string :status
      t.string :location
      t.text :description
      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :tracking_events, [ :task_id, :occurred_at ]
    add_index :tracking_events, :status
  end
end
