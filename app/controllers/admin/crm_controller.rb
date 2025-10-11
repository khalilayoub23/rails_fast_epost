module Admin
  class CrmController < ApplicationController
    before_action :require_admin!

    def index
      @stats = {
        hubspot: hubspot_stats,
        odoo: odoo_stats,
        recent_events: recent_integration_events,
        customer_sync: customer_sync_stats
      }
    end

    private

    def hubspot_stats
      {
        total_events: IntegrationEvent.where("payload->>'source' = ?", "hubspot").count,
        last_24h: IntegrationEvent.where("payload->>'source' = ?", "hubspot")
                                  .where("created_at > ?", 24.hours.ago).count,
        success_rate: calculate_success_rate("hubspot"),
        last_event: IntegrationEvent.where("payload->>'source' = ?", "hubspot").last
      }
    end

    def odoo_stats
      {
        total_events: IntegrationEvent.where("payload->>'source' = ?", "odoo").count,
        last_24h: IntegrationEvent.where("payload->>'source' = ?", "odoo")
                                  .where("created_at > ?", 24.hours.ago).count,
        success_rate: calculate_success_rate("odoo"),
        last_event: IntegrationEvent.where("payload->>'source' = ?", "odoo").last
      }
    end

    def recent_integration_events
      IntegrationEvent.where("payload->>'source' IN (?)", %w[hubspot odoo])
                      .order(created_at: :desc)
                      .limit(20)
    end

    def customer_sync_stats
      {
        total_customers: Customer.count,
        hubspot_synced: Customer.where.not(crm_id: nil).count,
        last_sync: Customer.order(updated_at: :desc).first&.updated_at,
        sync_pending: Task.where(status: "pending").count
      }
    end

    def calculate_success_rate(source)
      total = IntegrationEvent.where("payload->>'source' = ?", source).count
      return 0 if total.zero?

      success = IntegrationEvent.where("payload->>'source' = ?", source)
                                .where("status = 'success' OR error_message IS NULL")
                                .count
      ((success.to_f / total) * 100).round(1)
    end

    def require_admin!
      redirect_to root_path, alert: "Access denied" unless current_user&.admin?
    end
  end
end
