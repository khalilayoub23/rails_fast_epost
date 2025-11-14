import { Controller } from "@hotwired/stimulus"

// Mobile menu controller for public landing page navigation
export default class extends Controller {
  static targets = ["menu"]

  toggle(event) {
    event?.preventDefault()
    this.menuTarget.classList.toggle("hidden")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }

  // Close menu when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}
