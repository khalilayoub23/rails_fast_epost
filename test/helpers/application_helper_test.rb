require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "format_sek applies exchange rate and formatting" do
    previous = ENV.delete("SEK_EXCHANGE_RATE")
    ENV["SEK_EXCHANGE_RATE"] = "10.0"

    begin
      assert_equal "SEK100", format_sek(1000)
      assert_equal "SEK0", format_sek(nil)
    ensure
      previous ? ENV["SEK_EXCHANGE_RATE"] = previous : ENV.delete("SEK_EXCHANGE_RATE")
    end
  end
end
