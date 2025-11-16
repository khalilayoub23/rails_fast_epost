require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Rack::Test keeps system specs runnable in environments without Chrome/Chromedriver.
  driven_by :rack_test
end
