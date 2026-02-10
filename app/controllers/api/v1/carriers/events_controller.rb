module Api
  module V1
    module Carriers
      class EventsController < BaseController
        def index
          authorize TrackingEvent
          events = policy_scope(TrackingEvent)
            .joins(:task)
            .where(tasks: { carrier_id: carrier.id })
            .order(occurred_at: :desc)
            .limit(limit_param)

          render json: events.map { |event| event_payload(event) }
        end

        private

        def limit_param
          value = params[:limit].to_i
          value.positive? ? [ value, 100 ].min : 50
        end

        def event_payload(event)
          {
            id: event.id,
            title: event.title,
            event_type: event.event_type,
            status: event.status,
            description: event.description,
            occurred_at: event.occurred_at,
            task_id: event.task_id
          }
        end
      end
    end
  end
end
