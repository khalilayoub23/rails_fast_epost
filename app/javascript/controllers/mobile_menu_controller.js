import { Controller } from "@hotwired/stimulus"

// Mobile menu controller for Turbo Native bottom navigation
export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Bind escape key to close modal
    this.escapeHandler = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  toggle(event) {
    event.preventDefault()
    
    if (this.modalTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.escapeHandler)
    
    // Animate modal slide up
    requestAnimationFrame(() => {
      this.modalTarget.classList.add("animate-slide-up")
    })
  }

  close() {
    this.modalTarget.classList.add("hidden")
    this.modalTarget.classList.remove("animate-slide-up")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.escapeHandler)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  stopPropagation(event) {
    // Prevent click from bubbling to background overlay
    event.stopPropagation()
  }
}
