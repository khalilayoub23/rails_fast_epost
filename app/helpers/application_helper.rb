module ApplicationHelper
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
end
