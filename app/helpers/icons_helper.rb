module IconsHelper
  # Render custom SVG icon with optional size and classes
  def custom_icon(name, size: "24", css_class: "")
    icon_path = Rails.root.join("app", "assets", "images", "icons", "#{name}.svg")

    if File.exist?(icon_path)
      svg_content = File.read(icon_path)
      # Apply size and classes
      svg_content = svg_content.sub(/viewBox="[^"]*"/, "viewBox=\"0 0 64 64\" width=\"#{size}\" height=\"#{size}\" class=\"#{css_class}\"")
      raw(svg_content)
    else
      # Fallback to a simple icon
      content_tag(:div, "📦", class: "text-#{size} #{css_class}")
    end
  end

  # Quick access to specific icons
  def package_icon(size: "24", css_class: "")
    custom_icon("package-create", size: size, css_class: css_class)
  end

  def truck_icon(size: "24", css_class: "")
    custom_icon("truck-pickup", size: size, css_class: css_class)
  end

  def plane_icon(size: "24", css_class: "")
    custom_icon("plane-transit", size: size, css_class: css_class)
  end

  def delivery_icon(size: "24", css_class: "")
    custom_icon("delivery-truck", size: size, css_class: css_class)
  end

  def checkmark_icon(size: "24", css_class: "")
    custom_icon("checkmark-delivered", size: size, css_class: css_class)
  end

  def warning_icon(size: "24", css_class: "")
    custom_icon("warning-failed", size: size, css_class: css_class)
  end

  def return_icon(size: "24", css_class: "")
    custom_icon("return-package", size: size, css_class: css_class)
  end

  def mail_icon(size: "24", css_class: "")
    custom_icon("contact-mail", size: size, css_class: css_class)
  end

  def search_icon(size: "24", css_class: "")
    custom_icon("search-tracking", size: size, css_class: css_class)
  end

  def clock_icon(size: "24", css_class: "")
    custom_icon("clock-time", size: size, css_class: css_class)
  end

  def location_icon(size: "24", css_class: "")
    custom_icon("location-pin", size: size, css_class: css_class)
  end
end
