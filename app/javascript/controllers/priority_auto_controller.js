import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deliveryTime", "prioritySelect", "priorityHidden", "taskType"]
  static values = {
    legalTypes: String
  }

  connect() {
    this.update()
  }

  update() {
    const value = this.deliveryTimeTarget?.value
    const taskType = this.taskTypeTarget?.value
    const legalTypes = (this.legalTypesValue || "").split(",").map(type => type.trim()).filter(Boolean)
    const isLegal = legalTypes.includes(taskType)

    if (this.hasPrioritySelectTarget) {
      this.prioritySelectTarget.disabled = isLegal
      this.prioritySelectTarget.classList.toggle("cursor-not-allowed", isLegal)
      this.prioritySelectTarget.classList.toggle("opacity-80", isLegal)
    }

    if (!isLegal) {
      if (this.hasPriorityHiddenTarget) {
        this.priorityHiddenTarget.value = this.prioritySelectTarget?.value || "normal"
      }
      return
    }

    let priority = "normal"

    if (value) {
      const deliveryDate = new Date(value)
      if (!Number.isNaN(deliveryDate.getTime())) {
        const now = new Date()
        const diffMs = deliveryDate.getTime() - now.getTime()
        const diffHours = diffMs / (1000 * 60 * 60)
        const diffDays = diffHours / 24

        if (diffHours < 48) {
          priority = "express"
        } else if (diffDays < 2) {
          priority = "urgent"
        } else if (diffDays > 4) {
          priority = "normal"
        } else {
          priority = "urgent"
        }
      }
    }

    if (this.hasPrioritySelectTarget) {
      this.prioritySelectTarget.value = priority
    }
    if (this.hasPriorityHiddenTarget) {
      this.priorityHiddenTarget.value = priority
    }
  }
}
