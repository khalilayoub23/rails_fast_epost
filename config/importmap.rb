# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "stripe_checkout", to: "stripe_checkout/index.js"
pin "@stripe/stripe-js", to: "@stripe--stripe-js.js"

# Google Places autocomplete (frontend only)
pin "google_autocomplete", to: "google_autocomplete.js"

# Advanced features
pin "sortablejs" # @1.15.6

# flatpickr for datetime picker UI
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/esm/index.js"
