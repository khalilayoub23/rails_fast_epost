module Admin
  class BrandingController < ApplicationController
    before_action :require_admin!

    def show
    end

    def update
      save_logo(:light_logo, prefix: "logo")
      save_logo(:dark_logo,  prefix: "logo-dark")
      redirect_to admin_branding_path, notice: "Branding updated."
    rescue => e
      redirect_to admin_branding_path, alert: e.message
    end

    private

    def save_logo(param_key, prefix:)
      file = params[param_key]
      return unless file.present?
      ext = File.extname(file.original_filename).downcase
      allowed = %w[.svg .png .jpg .jpeg]
      raise "Unsupported file type. Allowed: SVG, PNG, JPG" unless allowed.include?(ext)

      # Clean up previous logo files for this prefix to avoid conflicts
      allowed.each do |e|
        path = Rails.root.join("public", "#{prefix}#{e}")
        File.delete(path) if File.exist?(path)
      end

      target = Rails.root.join("public", "#{prefix}#{ext}")
      File.open(target, "wb") { |f| f.write(file.read) }
    end

    def require_admin!
      redirect_to root_path, alert: "You are not authorized to access admin." unless current_user&.admin?
    end
  end
end
