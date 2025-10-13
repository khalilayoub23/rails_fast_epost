class DocumentTemplate < ApplicationRecord
  # Active Storage for PDF file attachments
  has_one_attached :pdf_file

  # Enums
  enum :template_type, {
    prawn_template: 0,      # Generate PDF from scratch using Prawn
    fillable_form: 1,       # Fill existing PDF form fields using HexaPDF
    hybrid: 2               # Combination of both approaches
  }

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 200 }
  validates :template_type, presence: true
  validates :category, length: { maximum: 100 }, allow_blank: true

  # Custom validation for fillable forms requiring PDF attachment
  validate :fillable_form_must_have_pdf

  # Scopes
  scope :active_templates, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_type, ->(type) { where(template_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  # Categories (can be moved to enum if needed)
  CATEGORIES = [
    "Customs Declaration",
    "Shipping Document",
    "Commercial Invoice",
    "Packing List",
    "Certificate of Origin",
    "Power of Attorney",
    "Legal Agreement",
    "Consent Form",
    "Other"
  ].freeze

  # Instance Methods

  # Extract variables from content (for Prawn templates)
  # Looks for {{variable_name}} patterns
  def extract_variables_from_content
    return [] unless content.present?

    content.scan(/\{\{(\w+)\}\}/).flatten.uniq
  end

  # Update variables schema
  def update_variables_schema!
    extracted = extract_variables_from_content
    self.variables ||= {}

    # Add new variables, preserve existing ones
    extracted.each do |var_name|
      variables[var_name] ||= {
        "type" => "string",
        "label" => var_name.titleize,
        "required" => true
      }
    end

    save!
  end

  # Generate PDF with provided variable values
  def generate_pdf(variable_values = {})
    case template_type.to_sym
    when :prawn_template
      PdfGeneratorService.generate_from_template(self, variable_values)
    when :fillable_form
      PdfGeneratorService.fill_form_pdf(self, variable_values)
    when :hybrid
      PdfGeneratorService.generate_hybrid_pdf(self, variable_values)
    end
  end

  # Check if template is ready for use
  def ready_for_use?
    active? && ((prawn_template? && content.present?) || (fillable_form? && pdf_file.attached?))
  end

  # Get file size in human-readable format
  def file_size
    return nil unless pdf_file.attached?

    size = pdf_file.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1024 * 1024
      "#{(size / 1024.0).round(2)} KB"
    else
      "#{(size / (1024.0 * 1024)).round(2)} MB"
    end
  end

  private

  def fillable_form_must_have_pdf
    if template_type == "fillable_form" && !pdf_file.attached? && persisted?
      errors.add(:pdf_file, "must be attached for fillable form templates")
    end
  end
end
