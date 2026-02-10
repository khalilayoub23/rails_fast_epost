# Hotwire Helper Methods
module HotwireHelper
  # Turbo Frame helpers
  def turbo_frame_request?
    request.headers["Turbo-Frame"].present?
  end

  def turbo_frame_id
    request.headers["Turbo-Frame"]
  end

  # Turbo Stream helpers
  def turbo_stream_request?
    request.headers["Accept"]&.include?("text/vnd.turbo-stream.html")
  end

  # Flash messages for Turbo Stream
  def turbo_stream_flash(type, message)
    turbo_stream.append "flash-messages", partial: "shared/flash_message",
                        locals: { type: type, message: message }
  end

  # Modal helpers
  def turbo_modal_tag(id, **options, &block)
    options[:data] ||= {}
    options[:data][:controller] = "modal"
    options[:class] = "fixed inset-0 z-999 flex items-center justify-center hidden #{options[:class]}"

    tag.div(id: id, **options) do
      concat tag.div(class: "fixed inset-0 bg-black/50 transition-opacity duration-300 opacity-0",
                    data: { modal_target: "backdrop", action: "click->modal#closeOnBackdrop" })
      concat tag.div(class: "relative bg-white dark:bg-boxdark rounded-lg shadow-xl max-w-lg w-full mx-4 transition-all duration-300 opacity-0 scale-95",
                    data: { modal_target: "container", action: "click->modal#stopPropagation" }) do
        yield
      end
    end
  end

  # Notification helpers
  def normalize_flash_type(type)
    case type.to_s
    when "notice", "success"
      :success
    when "alert", "error"
      :alert
    when "warning"
      :warning
    else
      :info
    end
  end

  def notification_tag(type, message, **options)
    options[:data] ||= {}
    options[:data][:controller] = "notification"
    options[:data][:notification_timeout_value] = options.delete(:timeout) || 5000
    options[:class] = notification_classes(type, options[:class])

    tag.div(**options) do
      concat tag.div(class: "flex items-start") do
        concat notification_icon(type)
        concat tag.div(class: "ml-3 flex-1") do
          concat tag.p(message, class: "text-sm font-medium")
        end
        concat tag.button(type: "button",
                         class: "ml-auto -mx-1.5 -my-1.5 rounded-lg p-1.5 inline-flex h-8 w-8 hover:bg-gray-100 dark:hover:bg-gray-700",
                         data: { action: "click->notification#close" }) do
          tag.span("×", class: "text-2xl leading-none")
        end
      end
    end
  end

  private

  def notification_classes(type, additional_classes)
    base = "flex p-4 mb-4 rounded-lg transition-all duration-300"
    type_classes = case type.to_sym
    when :success
      "bg-green-50 dark:bg-green-800 text-green-800 dark:text-green-200"
    when :error, :alert
      "bg-red-50 dark:bg-red-800 text-red-800 dark:text-red-200"
    when :warning
      "bg-yellow-50 dark:bg-yellow-800 text-yellow-800 dark:text-yellow-200"
    else
      "bg-blue-50 dark:bg-blue-800 text-blue-800 dark:text-blue-200"
    end

    [ base, type_classes, additional_classes ].compact.join(" ")
  end

  def notification_icon(type)
    icon = case type.to_sym
    when :success then "check_circle"
    when :error, :alert then "error"
    when :warning then "warning"
    else "info"
    end

    tag.span(icon, class: "material-icons")
  end
end
