require "test_helper"
require "fileutils"
require "warden/test/helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  parallelize(workers: 1)

  include Warden::Test::Helpers

  DRIVER = ENV.fetch("SYSTEM_TEST_DRIVER", "selenium_chrome_headless").to_sym
  DRIVER_MAP = {
    selenium: :chrome,
    selenium_chrome: :chrome,
    selenium_chrome_headless: :headless_chrome,
    selenium_headless: :headless_chrome,
    selenium_firefox: :firefox,
    selenium_firefox_headless: :headless_firefox
  }.freeze

  driver_alias = DRIVER_MAP.fetch(DRIVER, DRIVER)
  headless = driver_alias == :headless_chrome

  if driver_alias == :rack_test
    driven_by :rack_test
  else
    driven_by :selenium,
          using: driver_alias,
              screen_size: [ 1400, 1400 ] do |browser_options|
      if %i[firefox headless_firefox].include?(driver_alias)
        configure_firefox_options(browser_options, headless: driver_alias == :headless_firefox)
      else
        configure_chrome_options(browser_options, headless: headless)
      end
    end
  end

  setup do
    Warden.test_mode!
  end

  teardown do
    Warden.test_reset!
    Capybara.reset_sessions!
  end

  def authenticate_as(user, scope: :user)
    login_as(user, scope: scope)
  end

  def submit_form_with_request_submit(selector)
    page.execute_script("document.querySelector(#{selector.to_json}).requestSubmit()")
  end

  def click_with_retry(locator_type, locator, **options)
    attempts = 0

    begin
      find(locator_type, locator, **options).click
    rescue Selenium::WebDriver::Error::StaleElementReferenceError, Selenium::WebDriver::Error::UnknownError
      attempts += 1
      retry if attempts < 3
      raise
    end
  end

  class << self
    private

    def configure_firefox_options(options, headless: true)
      options.args << "--width=1400"
      options.args << "--height=1400"
      options.args << "--private-window"
      options.args << "--headless" if headless

      options.add_preference("permissions.default.desktop-notification", 2)
      options.add_preference("dom.webnotifications.enabled", false)
      options.add_preference("media.autoplay.default", 0)
      options.add_preference("intl.accept_languages", "en-US,en")
      options.add_preference("dom.importMaps.enabled", true)

      firefox_binary = ENV["FIREFOX_BIN"] || "/usr/local/bin/firefox"
      options.binary = firefox_binary if firefox_binary && File.exist?(firefox_binary)
    end

    def configure_chrome_options(chrome_options, headless: true)
      chrome_flags = %w[
        --window-size=1400,1400
        --disable-dev-shm-usage
        --no-sandbox
        --disable-setuid-sandbox
        --blink-settings=imagesEnabled=false
        --disable-features=VizDisplayCompositor
      ]

      chrome_flags.each { |flag| chrome_options.add_argument(flag) }
      chrome_options.add_argument("--headless=new") if headless

      chrome_binary = ENV["GOOGLE_CHROME_BIN"]
      chrome_options.binary = chrome_binary if chrome_binary.present?
    end
  end
end
