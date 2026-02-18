require "application_system_test_case"

class LocaleSwitcherTest < ApplicationSystemTestCase
  test "visitor can open locale picker and change language" do
    visit pages_contact_path

    switcher = find("[data-testid='locale-switcher']", match: :first)
    assert_selector("[data-testid='locale-switcher'][data-locale-switcher-ready='true']")
    click_with_retry(:css, "[data-testid='locale-switcher'] button", match: :first)

    within(switcher) do
      assert_selector ".locale-switcher__menu", visible: true
      click_with_retry(:link_or_button, "עברית", match: :first)
    end

    assert_current_path(pages_contact_path(locale: :he))

    assert_equal "he", page.evaluate_script("document.documentElement.getAttribute('lang')")
  end
end
