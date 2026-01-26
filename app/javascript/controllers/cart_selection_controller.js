import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleAll", "itemCheckbox", "amountInput"]

  connect() {
    this.sync()
  }

  toggleAll() {
    const checked = this.toggleAllTarget.checked
    this.itemCheckboxTargets.forEach((checkbox) => {
      checkbox.checked = checked
    })

    this.updateToggleAllState()
    this.updateAmountInputs()
  }

  sync() {
    this.updateToggleAllState()
    this.updateAmountInputs()
  }

  updateToggleAllState() {
    if (!this.hasToggleAllTarget) return

    const total = this.itemCheckboxTargets.length
    if (total === 0) return

    const checkedCount = this.itemCheckboxTargets.filter((checkbox) => checkbox.checked).length
    const allChecked = checkedCount === total
    const noneChecked = checkedCount === 0

    this.toggleAllTarget.indeterminate = !allChecked && !noneChecked
    this.toggleAllTarget.checked = allChecked
  }

  updateAmountInputs() {
    if (!this.hasAmountInputTarget) return

    const selectedTaskIds = new Set(
      this.itemCheckboxTargets.filter((checkbox) => checkbox.checked).map((checkbox) => checkbox.dataset.taskId)
    )

    this.amountInputTargets.forEach((input) => {
      const taskId = input.dataset.taskId
      const enabled = selectedTaskIds.has(taskId)
      input.disabled = !enabled
    })
  }
}
