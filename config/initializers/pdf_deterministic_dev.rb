# Optional: allow deterministic PDFs during development when debugging diffs
if Rails.env.development? && ENV["PDF_DETERMINISTIC"].present?
  ENV["PDF_DETERMINISTIC"] = "1"
end
