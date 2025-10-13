import { Controller } from "@hotwired/stimulus"

// Notification/Flash message controller
export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 5000 },
    removeAfter: { type: Boolean, default: true }
  }

  connect() {
    if (this.removeAfterValue) {
      this.timeoutId = setTimeout(() => {
        this.close()
      }, this.timeoutValue)
    }

    // Animate in
    requestAnimationFrame(() => {
      this.element.classList.remove("opacity-0", "translate-x-full")
      this.element.classList.add("opacity-100", "translate-x-0")
    })
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  close() {
    // Animate out
    this.element.classList.remove("opacity-100", "translate-x-0")
    this.element.classList.add("opacity-0", "translate-x-full")

    // Remove after animation
    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  pauseTimeout() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  resumeTimeout() {
    if (this.removeAfterValue) {
      this.timeoutId = setTimeout(() => {
        this.close()
      }, this.timeoutValue)
    }
  }
}
