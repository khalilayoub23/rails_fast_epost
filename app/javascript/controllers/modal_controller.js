import { Controller } from "@hotwired/stimulus"

// Modal controller for dialogs and popups
export default class extends Controller {
  static targets = ["container", "backdrop"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    if (this.openValue) {
      this.open()
    }

    // Close on escape key
    this.escapeHandler = this.handleEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
    document.body.classList.remove("no-scroll")
  }

  open() {
    this.element.classList.remove("hidden")
    document.body.classList.add("no-scroll")
    document.addEventListener("keydown", this.escapeHandler)

    // Animate in
    requestAnimationFrame(() => {
      if (this.hasBackdropTarget) {
        this.backdropTarget.classList.remove("opacity-0")
        this.backdropTarget.classList.add("opacity-100")
      }
      
      if (this.hasContainerTarget) {
        this.containerTarget.classList.remove("opacity-0", "scale-95")
        this.containerTarget.classList.add("opacity-100", "scale-100")
      }
    })

    // Dispatch event
    this.element.dispatchEvent(new CustomEvent("modal:opened", {
      bubbles: true
    }))
  }

  close() {
    // Animate out
    if (this.hasBackdropTarget) {
      this.backdropTarget.classList.remove("opacity-100")
      this.backdropTarget.classList.add("opacity-0")
    }
    
    if (this.hasContainerTarget) {
      this.containerTarget.classList.remove("opacity-100", "scale-100")
      this.containerTarget.classList.add("opacity-0", "scale-95")
    }

    // Remove after animation
    setTimeout(() => {
      this.element.classList.add("hidden")
      document.body.classList.remove("no-scroll")
      document.removeEventListener("keydown", this.escapeHandler)

      // Dispatch event
      this.element.dispatchEvent(new CustomEvent("modal:closed", {
        bubbles: true
      }))
    }, 300)
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.element || event.target === this.backdropTarget) {
      this.close()
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
