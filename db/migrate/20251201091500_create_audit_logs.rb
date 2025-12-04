class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :delivery, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.string :role
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
