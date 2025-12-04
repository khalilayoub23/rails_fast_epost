require "application_system_test_case"

class PublicHeaderTest < ApplicationSystemTestCase
  test "header offsets content and shows locale switcher" do
    resize_window_to_desktop

    visit root_path

    body = find("body")
    nav = find("nav.public-nav")
    main = find("main")

    main_class = main[:class].to_s
    assert_includes main_class, "pt-20", "main should reserve vertical space via pt-20"

    within nav do
      assert_selector ".public-nav__actions"
      assert_selector "[data-testid='locale-switcher']"
    end
  end

  test "mobile rtl header toggles menu" do
    resize_window_to_mobile

    visit root_path(locale: :ar)

    nav = find("nav.public-nav")
    assert_equal "rtl", nav[:dir]

    find("#mobile-menu-button").click
    assert_selector "#mobile-menu:not(.hidden)", visible: :all, wait: 5
  end

  private

  def resize_window_to_desktop
    resize_window(1280, 900)
  end

  def resize_window_to_mobile
    resize_window(390, 844)
  end

  def resize_window(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  rescue StandardError
    # headless drivers like rack_test do not expose window sizing; ignore when unavailable
  end
end
