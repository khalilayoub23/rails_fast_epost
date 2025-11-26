module ControlPanel
  class BaseController < ApplicationController
    layout "control_panel"

    helper_method :accessible_senders, :accessible_lawyers, :accessible_sellers

    before_action :authenticate_user!
    before_action :require_control_panel_access!
    before_action :set_control_panel_title

    private

    def require_control_panel_access!
      return if current_user&.admin? || current_user&.operations_manager?
      return if current_user&.carrier_memberships&.exists?

      message = t("messages.unauthorized", default: "You are not authorized to access control panels yet.")
      redirect_to(root_path, alert: message)
    end

    def require_operations_role!
      return if current_user&.admin? || current_user&.operations_manager?

      message = t("messages.unauthorized", default: "Operations access required.")
      redirect_to(root_path, alert: message)
    end

    def accessible_senders
      return Sender.none unless current_user&.admin? || current_user&.operations_manager?

      Sender.order(Arel.sql("LOWER(name)"))
    end

    def accessible_lawyers
      return Lawyer.none unless current_user&.admin? || current_user&.operations_manager?

      Lawyer.order(Arel.sql("LOWER(name)"))
    end

    def accessible_sellers
      accessible_senders.where(sender_type: Sender.sender_types[:business])
    end

    def resolve_panel_entity(scope, session_key:, param_key:)
      return nil if scope.none?

      requested_id = params[param_key]&.presence || session[session_key]
      record = scope.find_by(id: requested_id) || scope.first
      session[session_key] = record.id if record
      record
    end

    def set_control_panel_title
      @control_panel_title ||= "Control Panel"
    end
  end
end
