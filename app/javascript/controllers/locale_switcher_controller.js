import { Controller } from "@hotwired/stimulus"

// Locale switcher dropdown that opens on hover or click for desktop/touch parity
export default class extends Controller {
  static targets = ["button", "menu"]
  static values = { delay: Number }

  connect() {
    this.closeTimeout = null
    this.pinnedByClick = false
    this.outsideHandler = this.handleOutsideClick.bind(this)
    document.addEventListener("pointerdown", this.outsideHandler)
    this.element.dataset.localeSwitcherReady = "true"
  }

  disconnect() {
    document.removeEventListener("pointerdown", this.outsideHandler)
    this.clearCloseTimeout()
    this.element.dataset.localeSwitcherReady = "false"
  }

  toggle(event) {
    event.preventDefault()
    if (this.isOpen && this.pinnedByClick) {
      this.pinnedByClick = false
      this.close()
      return
    }

    if (this.isOpen && !this.pinnedByClick) {
      this.pinnedByClick = true
      return
    }

    this.pinnedByClick = true
    this.open()
  }

  open() {
    this.clearCloseTimeout()
    if (this.isOpen) return
    this.element.classList.add("is-open")
    this.buttonTarget?.setAttribute("aria-expanded", "true")
  }

  openFromHover() {
    this.pinnedByClick = false
    this.open()
  }

  openFromFocus() {
    this.pinnedByClick = false
    this.open()
  }

  close() {
    this.clearCloseTimeout()
    if (!this.isOpen) return
    this.element.classList.remove("is-open")
    this.buttonTarget?.setAttribute("aria-expanded", "false")
    this.pinnedByClick = false
  }

  scheduleClose(event) {
    if (this.pinnedByClick) return
    if (event?.relatedTarget && this.element.contains(event.relatedTarget)) {
      return
    }

    this.clearCloseTimeout()
    this.closeTimeout = window.setTimeout(() => {
      if (this.pinnedByClick) return
      this.close()
    }, this.closeDelay)
  }

  cancelClose() {
    this.clearCloseTimeout()
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.pinnedByClick = false
      this.close()
    }
  }

  clearCloseTimeout() {
    if (this.closeTimeout) {
      window.clearTimeout(this.closeTimeout)
      this.closeTimeout = null
    }
  }

  get isOpen() {
    return this.element.classList.contains("is-open")
  }

  get closeDelay() {
    return this.hasDelayValue ? this.delayValue : 200
  }
}
