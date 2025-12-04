import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "icon"]

  connect() {
    this.hidden = true
  }

  toggle(e) {
    e.preventDefault()
    this.hidden = !this.hidden
    
    if (this.hidden) {
      this.inputTarget.type = "password"
      this.iconTarget.textContent = "visibility"
    } else {
      this.inputTarget.type = "text"
      this.iconTarget.textContent = "visibility_off"
    }
  }
}
