import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["from", "to", "days"]

  update() {
    const fromValue = this.fromTarget?.value
    const toValue = this.toTarget?.value
    if (!fromValue || !toValue || !this.hasDaysTarget) return

    const fromDate = new Date(fromValue)
    const toDate = new Date(toValue)
    if (Number.isNaN(fromDate.getTime()) || Number.isNaN(toDate.getTime())) return

    const diffMs = toDate.getTime() - fromDate.getTime()
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24)) + 1
    this.daysTarget.value = diffDays > 0 ? diffDays : ""
  }
}
