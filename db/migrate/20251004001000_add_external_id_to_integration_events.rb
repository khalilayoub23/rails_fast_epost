class AddExternalIdToIntegrationEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :integration_events, :external_id, :string
    add_index :integration_events, [ :provider, :external_id ], unique: true, where: "external_id IS NOT NULL", name: "index_integration_events_on_provider_and_external_id"
  end
end
