return unless defined?(Grover)

Grover.configure do |config|
  config.root_url = ENV.fetch("APP_HOST", "https://example.com")
  config.options = {
    format: "A4",
    margin: {
      top: "10mm",
      right: "15mm",
      bottom: "20mm",
      left: "15mm"
    },
    preferCSSPageSize: true,
    printBackground: true,
    displayHeaderFooter: false,
    viewport: {
      width: 1280,
      height: 720
    },
    launchOptions: {
      args: [ "--no-sandbox", "--disable-dev-shm-usage", "--disable-web-security" ],
      dumpio: false
    }
  }
end
