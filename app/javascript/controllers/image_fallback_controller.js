import { Controller } from "@hotwired/stimulus"

// Hides broken images inside the controller element.
export default class extends Controller {
  connect() {
    this.handleError = this.handleError.bind(this)
    this.element.addEventListener('error', this.handleError, true)
  }

  disconnect() {
    this.element.removeEventListener('error', this.handleError, true)
  }

  handleError(event) {
    const el = event.target
    if (el && el.tagName === 'IMG') {
      el.classList.add('hidden')
      // remove src to avoid repeated network attempts
      try { el.removeAttribute('src') } catch (e) {}
    }
  }
}
