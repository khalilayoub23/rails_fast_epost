require "application_system_test_case"

class LocaleSwitcherTest < ApplicationSystemTestCase
  test "visitor can open locale picker and change language" do
    visit pages_contact_path

    switcher = find("[data-testid='locale-switcher']", match: :first)
    switcher.find("button").click

    within(switcher) do
      assert_selector ".locale-switcher__menu", visible: true
      click_link "עברית"
    end

    assert_equal "he", page.find("html")[:lang]
  end
end
