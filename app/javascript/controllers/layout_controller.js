import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.updateLayout()
  }

  updateLayout() {
    // Update HTML dir attribute for RTL/LTR support across Turbo navigations
    const dir = this.element.dataset.direction
    if (dir && document.documentElement.getAttribute("dir") !== dir) {
      document.documentElement.setAttribute("dir", dir)
    }
    
    // Update HTML lang attribute if needed
    const lang = this.element.dataset.lang
    if (lang && document.documentElement.getAttribute("lang") !== lang) {
      document.documentElement.setAttribute("lang", lang)
    }
  }
}
