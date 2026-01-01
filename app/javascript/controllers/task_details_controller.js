import { Controller } from "@hotwired/stimulus"

// Toggle visibility of the task details panel on the task show page
export default class extends Controller {
  static targets = ["panel", "icon", "label"]

  connect() {
    this.expanded = false
    this.update()
  }

  toggle(event) {
    event.preventDefault()
    this.expanded = !this.expanded
    this.update()
  }

  update() {
    this.panelTarget.classList.toggle("hidden", !this.expanded)
    this.panelTarget.classList.toggle("block", this.expanded)
    this.iconTarget.textContent = this.expanded ? "expand_less" : "unfold_more"
    this.labelTarget.textContent = this.expanded ? "Hide details" : "Show details"
  }
}
