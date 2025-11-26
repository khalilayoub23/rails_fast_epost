module ControlPanel
  module Carriers
    class BaseController < ControlPanel::BaseController
      before_action :require_carrier_membership!
      before_action :set_carrier_panel_title

      private

      def set_carrier_panel_title
        @control_panel_title ||= "Carrier Control Panel"
      end
    end
  end
end
