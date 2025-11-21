import { Controller } from "@hotwired/stimulus"

// Dropdown controller supports two interaction modes:
// 1. Hover (default for desktop nav): show menu on mouseenter, hide on mouseleave.
// 2. Click (fallback for touch/mobile): toggle on click.
// Adds auto-dismiss when clicking outside.
export default class extends Controller {
  static targets = ["menu"]
  static values = { hover: { type: Boolean, default: true } }

  connect() {
    this.boundOutside = this.outsideClick.bind(this)
    document.addEventListener("click", this.boundOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutside)
  }

  // Click fallback
  toggle(event) {
    if (this.hoverValue && this.deviceSupportsHover()) return
    event.preventDefault()
    this.menuTarget.classList.toggle("hidden")
  }

  // Hover handlers
  show() {
    if (!this.hoverValue) return
    clearTimeout(this.timeout)
    this.menuTarget.classList.remove("hidden")
  }

  hide() {
    if (!this.hoverValue) return
    this.timeout = setTimeout(() => {
      this.menuTarget.classList.add("hidden")
    }, 200)
  }

  outsideClick(e) {
    if (!this.hasMenuTarget) return
    if (this.element.contains(e.target)) return
    this.menuTarget.classList.add("hidden")
  }

  deviceSupportsHover() {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") return false
    return window.matchMedia("(hover: hover) and (pointer: fine)").matches
  }
}
