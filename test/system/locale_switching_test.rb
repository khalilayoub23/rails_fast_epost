require "application_system_test_case"

class LocaleSwitchingTest < ApplicationSystemTestCase
  test "landing page switches to Hebrew with RTL direction" do
    visit root_path(locale: :he)

    # Check hero text in Hebrew
    assert_text "מהירות פוגשת"

    # Verify RTL direction
    assert_selector "html[dir='rtl']"
    assert_selector "html[lang='he']"

    # Check locale code in dropdown trigger
    assert_selector "button", text: "HE"
  end

  test "landing page switches to Arabic with RTL direction" do
    visit root_path(locale: :ar)

    # Check hero text in Arabic
    assert_text "السرعة تلتقي"

    # Verify RTL direction
    assert_selector "html[dir='rtl']"
    assert_selector "html[lang='ar']"
  end

  test "landing page switches to Russian with LTR direction" do
    visit root_path(locale: :ru)

    # Check hero text in Russian
    assert_text "СКОРОСТЬ ВСТРЕЧАЕТ"

    # Verify LTR direction
    assert_selector "html[dir='ltr']"
    assert_selector "html[lang='ru']"
  end

  test "landing page defaults to English" do
    Capybara.using_session("default-locale-check") do
      visit root_path

      # Check hero text in English
      assert_text "SPEED MEETS"

      # Verify LTR direction
      assert_selector "html[dir='ltr']"
      assert_selector "html[lang='en']"
    end
  end

  test "locale switcher shows all language options" do
    visit root_path(locale: :en)

    within "[data-controller='dropdown'][data-dropdown-hover-value='true']" do
      find("button[data-action*='dropdown#toggle']", match: :first).click

      %w[en he ar ru].each do |locale|
        assert_selector "a[href*='locale=#{locale}']", visible: :all
      end
    end
  end

  test "switching locale via URL param changes session and persists" do
    visit root_path(locale: :he)
    assert_selector "html[lang='he']"

    # Navigate to another page (services) without explicit locale param
    click_link href: pages_services_path

    # Should maintain Hebrew locale
    assert_selector "html[lang='he']"
  end

  test "footer and buttons render in selected locale" do
    visit root_path(locale: :he)

    # Check footer text
    assert_text "כל הזכויות שמורות"

    # Check CTA button
    assert_selector "span", text: "קבל הצעת מחיר"
  end
end
