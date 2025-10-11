module Admin
  class DashboardLayoutsController < ApplicationController
    protect_from_forgery with: :exception
    before_action :require_admin!

    def update
  order = Array(params[:order] || params.dig(:_json, :order))
  spans = Array(params[:spans] || params.dig(:_json, :spans))
      if order.empty? && request.content_type == "application/json"
        # Parse raw JSON body
        begin
          payload = JSON.parse(request.raw_post) rescue {}
          order = Array(payload["order"]) if order.empty?
        rescue JSON::ParserError
        end
      end

      raise ActionController::BadRequest, "order is required" if order.empty?

      path = Rails.root.join("config", "dashboard_layout.json")
      original = JSON.parse(File.read(path)) rescue []
      # Keep spans from original; reorder by submitted order
      by_id = original.index_by { |w| w["id"] }
      updated = order.filter_map do |id|
        item = by_id[id] || { "id" => id, "span" => "col-span-12" }
        if found = spans.find { |s| s["id"] == id && s["span"].present? }
          item = item.merge("span" => found["span"])
        end
        item
      end
      File.write(path, JSON.pretty_generate(updated))
      head :no_content
    end
  end
end
