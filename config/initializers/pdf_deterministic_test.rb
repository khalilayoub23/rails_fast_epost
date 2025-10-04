# Sets deterministic PDF output during test runs to make snapshot tests stable
if Rails.env.test?
  ENV["PDF_DETERMINISTIC"] ||= "1"
end
