import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggleAll", "itemCheckbox"]

  connect() {
    this.sync()
  }

  toggleAll() {
    const checked = this.toggleAllTarget.checked
    this.itemCheckboxTargets.forEach((checkbox) => {
      checkbox.checked = checked
    })

    this.updateToggleAllState()
  }

  sync() {
    this.updateToggleAllState()
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
}
