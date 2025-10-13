# Turbo Streams Broadcasting Concern
module TurboStreamsBroadcasting
  extend ActiveSupport::Concern

  included do
    after_create_commit -> { broadcast_created }
    after_update_commit -> { broadcast_updated }
    after_destroy_commit -> { broadcast_destroyed }
  end

  private

  def broadcast_created
    broadcast_prepend_to(
      turbo_stream_name,
      target: turbo_stream_target,
      partial: turbo_stream_partial,
      locals: { model_name.element.to_sym => self }
    )
  end

  def broadcast_updated
    broadcast_replace_to(
      turbo_stream_name,
      target: self,
      partial: turbo_stream_partial,
      locals: { model_name.element.to_sym => self }
    )
  end

  def broadcast_destroyed
    broadcast_remove_to(
      turbo_stream_name,
      target: self
    )
  end

  # Override these methods in your models
  def turbo_stream_name
    [ self.class.model_name.plural, "list" ].join("_")
  end

  def turbo_stream_target
    [ self.class.model_name.plural, "list" ].join("_")
  end

  def turbo_stream_partial
    "#{self.class.model_name.plural}/#{model_name.element}"
  end
end
