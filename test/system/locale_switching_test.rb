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
    visit root_path
    
    # Check hero text in English
    assert_text "SPEED MEETS"
    
    # Verify LTR direction
    assert_selector "html[dir='ltr']"
    assert_selector "html[lang='en']"
  end

  test "locale switcher shows all language options" do
    visit root_path(locale: :en)
    
    # Hover over language dropdown (in real browser this would open it)
    # For headless test we check the links exist in the menu
    within "[data-controller='dropdown']" do
      assert_selector "a[href*='locale=en']"
      assert_selector "a[href*='locale=he']"
      assert_selector "a[href*='locale=ar']"
      assert_selector "a[href*='locale=ru']"
    end
  end

  test "switching locale via URL param changes session and persists" do
    visit root_path(locale: :he)
    assert_selector "html[lang='he']"
    
    # Navigate to another page (services) without explicit locale param
    click_link "שירותים" # Hebrew "Services"
    
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
