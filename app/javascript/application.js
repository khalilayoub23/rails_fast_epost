// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Turbo configuration
import { Turbo } from "@hotwired/turbo-rails"

// Configure Turbo Drive
Turbo.session.drive = true

// Add progress bar configuration
document.addEventListener("turbo:before-fetch-request", (event) => {
  // Custom loading indicator can be added here
})

document.addEventListener("turbo:load", () => {
  // Re-initialize components after Turbo navigation
  console.log("Turbo loaded")
})

// Handle form submissions
document.addEventListener("turbo:submit-end", (event) => {
  if (event.detail.success) {
    // Form submitted successfully
  }
})

// Handle errors
document.addEventListener("turbo:frame-missing", (event) => {
  event.preventDefault()
  console.error("Turbo Frame missing:", event.detail)
})
