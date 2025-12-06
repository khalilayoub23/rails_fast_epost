module ApplicationHelper
  include HotwireHelper
  
  # RTL (Right-to-Left) language support
  RTL_LOCALES = [ :ar, :he, :fa, :ur ].freeze

  def rtl?
    RTL_LOCALES.include?(I18n.locale)
  end

  def text_direction
    rtl? ? "rtl" : "ltr"
  end

  def text_align_class
    rtl? ? "text-right" : "text-left"
  end

  def float_start_class
    rtl? ? "float-right" : "float-left"
  end

  def float_end_class
    rtl? ? "float-left" : "float-right"
  end

  def margin_start_class(size = "4")
    rtl? ? "mr-#{size}" : "ml-#{size}"
  end

  def margin_end_class(size = "4")
    rtl? ? "ml-#{size}" : "mr-#{size}"
  end

  def padding_start_class(size = "4")
    rtl? ? "pr-#{size}" : "pl-#{size}"
  end

  def padding_end_class(size = "4")
    rtl? ? "pl-#{size}" : "pr-#{size}"
  end

  def border_start_class
    rtl? ? "border-r" : "border-l"
  end

  def border_end_class
    rtl? ? "border-l" : "border-r"
  end

  def switch_locale_path(locale)
    raw_params = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
    filtered = raw_params.except(:controller, :action, :locale, "controller", "action", "locale")
    url_for(filtered.merge(locale: locale, only_path: true))
  rescue ActionController::UrlGenerationError
    url_for(controller: controller_name, action: action_name, locale: locale, only_path: true)
  end

  # Check if request is from Turbo Native iOS or Android app
  def turbo_native_app?
    request.user_agent.to_s.match?(/Turbo Native/)
  end

  # Check if request is from iOS Turbo Native app
  def turbo_native_ios?
    request.user_agent.to_s.match?(/Turbo Native iOS/)
  end

  # Check if request is from Android Turbo Native app
  def turbo_native_android?
    request.user_agent.to_s.match?(/Turbo Native Android/)
  end

  # Renders the brand logo with light/dark variants when available.
  # Looks for (priority): svg, png, jpg, jpeg in app/assets/images then public/.
  # If both light (logo.*) and dark (logo-dark.*) exist, renders both and toggles via CSS.
  # size: :sm, :md, :lg controls height classes.
  def brand_logo_tag(size: :md)
    size_class = case size
    when :sm then "h-8"
    when :lg then "h-12"
    else "h-10"
    end

                  # Public: Resolve current light logo URL if present (nil if none)
                  def current_light_logo_url
                    logo_url_for_prefix("logo")
                  end

                  # Public: Resolve current dark logo URL if present (nil if none)
                  def current_dark_logo_url
                    logo_url_for_prefix("logo-dark")
                  end

    light = find_logo_variant(%w[logo.svg logo.png logo.jpg logo.jpeg])
    dark  = find_logo_variant(%w[logo-dark.svg logo-dark.png logo-dark.jpg logo-dark.jpeg])

      if dark.present?
      # Render both: light visible in light theme, dark in dark theme
      safe_join([
          image_tag(resolve_logo_url(light || fallback_logo), alt: "Fast Epost", class: "brand-logo-img brand-logo--light #{size_class} w-auto"),
          image_tag(resolve_logo_url(dark), alt: "Fast Epost", class: "brand-logo-img brand-logo--dark #{size_class} w-auto")
      ])
      else
        image_tag(resolve_logo_url(light || fallback_logo), alt: "Fast Epost", class: "brand-logo-img #{size_class} w-auto")
      end
  end

  private

    def logo_url_for_prefix(prefix)
      name = find_logo_variant([ "#{prefix}.svg", "#{prefix}.png", "#{prefix}.jpg", "#{prefix}.jpeg" ])
      resolve_logo_url(name) if name
    end

  def fallback_logo
    find_logo_variant(%w[icon.svg icon.png icon.jpg icon.jpeg]) || "icon.png"
  end

  def find_logo_variant(candidates)
    candidates.find do |name|
      Rails.root.join("app/assets/images", name).exist? || Rails.root.join("public", name).exist?
    end
  end

    def resolve_logo_url(name)
      return name if name.start_with?("/")
      if Rails.root.join("public", name).exist?
        "/#{name}"
      else
        asset_path(name)
      end
    end

  # Flash message helper for Turbo Stream responses
  def dom_id_for_flash(type)
    "flash-#{type}-#{Time.current.to_i}"
  end

  def format_sek(amount_cents, precision: 0)
    return number_to_currency(0, unit: "SEK", precision: precision) if amount_cents.nil?

    rate = ENV.fetch("SEK_EXCHANGE_RATE", "11.0").to_f
    amount_sek = (amount_cents.to_i / 100.0) * rate
    number_to_currency(amount_sek, unit: "SEK", precision: precision)
  end

  def form_input_base_classes
    "mt-2 w-full rounded-xl border border-gray-600 bg-gray-900/60 px-3 py-2 text-white focus:border-yellow-400 focus:ring-0"
  end

  def form_input_classes(object, method, base_classes: form_input_base_classes, errors_for: nil)
    return base_classes unless object.respond_to?(:errors)

    if (messages = field_errors_for(object, method, errors_for)).any?
      updated = base_classes
        .gsub("border-gray-600", "border-red-500")
        .gsub("focus:border-yellow-400", "focus:border-red-500")
        .gsub("focus:ring-0", "focus:ring-1 focus:ring-red-500")

      updated.include?("bg-red-900/10") ? updated : "#{updated} bg-red-900/10"
    else
      base_classes
    end
  end

  def form_error_message(object, method, errors_for: nil)
    return unless object.respond_to?(:errors)

    messages = field_errors_for(object, method, errors_for)
    field_name = (errors_for.presence || method).to_s
    dom_id = form_field_dom_id(object, method)
    content = messages.first.to_s
    classes = [ "mt-1", "text-xs", "text-red-400", "font-medium" ]
    classes << "hidden" if content.blank?

    tag.p(content,
          class: classes.join(" "),
          data: {
            delivery_form_target: "error",
            delivery_form_error_name: field_name,
            delivery_form_error_present: content.present?.to_s,
            form_validation_target: "message",
            field: dom_id,
            form_validation_state: (content.present? ? "visible" : "hidden"),
            server_message: (content.present? ? "true" : "false")
          })
  end

  def form_field_dom_id(object, method)
    base = object.try(:model_name)&.param_key
    return method.to_s unless base.present?

    "#{base}_#{method}"
  end

  def field_errors_for(object, method, errors_for)
    return [] unless object.respond_to?(:errors)

    keys = []
    keys << (errors_for.present? ? errors_for.to_sym : method.to_sym)

    if errors_for.nil? && method.to_s.end_with?("_id")
      keys << method.to_s.delete_suffix("_id").to_sym
    end

    keys.uniq.each do |key|
      messages = Array.wrap(object.errors[key])
      return messages if messages.present?
    end

    []
  end
end
