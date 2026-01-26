import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["taskType", "section"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.taskTypeTarget?.value
    this.sectionTargets.forEach((section) => {
      const types = (section.dataset.taskTypes || "").split(",").map((value) => value.trim()).filter(Boolean)
      if (types.length === 0) return

      if (types.includes(type)) {
        section.classList.remove("hidden")
      } else {
        section.classList.add("hidden")
      }
    })
  }
}
