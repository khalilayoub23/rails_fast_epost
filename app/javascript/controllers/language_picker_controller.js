import { Controller } from "@hotwired/stimulus"

// Dedicated controller for the locale switcher to guarantee click/tap support
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.boundOutside = this.handleOutsideClick.bind(this)
    document.addEventListener("click", this.boundOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutside)
  }

  toggle(event) {
    event.preventDefault()
    if (!this.hasMenuTarget || !this.hasButtonTarget) return

    if (this.menuTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.menuTarget.classList.remove("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "true")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}
