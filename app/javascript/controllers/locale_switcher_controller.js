import { Controller } from "@hotwired/stimulus"

// Locale switcher dropdown that opens on hover or click for desktop/touch parity
export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.outsideHandler = this.handleOutsideClick.bind(this)
    document.addEventListener("pointerdown", this.outsideHandler)
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.outsideHandler)
  }

  toggle(event) {
    event.preventDefault()
    this.isOpen ? this.close() : this.open()
  }

  open() {
    if (this.isOpen) return
    this.element.classList.add("is-open")
    this.buttonTarget?.setAttribute("aria-expanded", "true")
  }

  close() {
    if (!this.isOpen) return
    this.element.classList.remove("is-open")
    this.buttonTarget?.setAttribute("aria-expanded", "false")
  }

  handleFocusOut(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.close()
    }
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  get isOpen() {
    return this.element.classList.contains("is-open")
  }
}
