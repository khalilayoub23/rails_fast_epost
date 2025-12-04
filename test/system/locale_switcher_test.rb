require "application_system_test_case"

class LocaleSwitcherTest < ApplicationSystemTestCase
  test "visitor can open locale picker and change language" do
    visit pages_contact_path

    switcher = find("[data-testid='locale-switcher']", match: :first)
    assert_selector("[data-testid='locale-switcher'][data-locale-switcher-ready='true']")
    switcher.find("button").click

    puts page.evaluate_script('document.querySelector("[data-testid=\'locale-switcher\']").className')
    puts page.evaluate_script('window.getComputedStyle(document.querySelector("[data-testid=\'locale-switcher\'] .locale-switcher__menu")).visibility')
    puts page.evaluate_script('document.querySelector("[data-testid=\'locale-switcher\'] .locale-switcher__menu").offsetWidth')
    puts page.evaluate_script('document.querySelector("[data-testid=\'locale-switcher\'] .locale-switcher__menu").offsetHeight')
    puts page.evaluate_script('window.getComputedStyle(document.querySelector("[data-testid=\'locale-switcher\'] .locale-switcher__menu")).display')
    puts page.evaluate_script('window.getComputedStyle(document.querySelector("[data-testid=\'locale-switcher\'] .locale-switcher__menu")).opacity')

    within(switcher) do
      assert_selector ".locale-switcher__menu", visible: true
      click_link "עברית"
    end

    assert_current_path(pages_contact_path(locale: :he))

    assert_equal "he", page.evaluate_script("document.documentElement.getAttribute('lang')")
  end
end
