import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pickupInput", "dropoffInput"]
  static values = {
    home: String,
    office: String
  }

  fill(event) {
    const field = event.params.field || event.currentTarget?.dataset?.addressShortcutsFieldParam
    const type = event.params.type || event.currentTarget?.dataset?.addressShortcutsTypeParam
    const address = (type === "home" ? this.homeValue : this.officeValue).toString().trim()
    if (!address) return

    const target = field === "pickup" ? this.pickupInputTarget : this.dropoffInputTarget
    if (!target) return

    target.value = address
    target.dispatchEvent(new Event("input", { bubbles: true }))
    target.dispatchEvent(new Event("change", { bubbles: true }))
    // Visual selection: mark the clicked shortcut as selected and clear siblings
    try {
      const container = event.currentTarget.closest('[data-controller="address-shortcuts"]') || this.element
      const buttons = container.querySelectorAll('button[data-address-shortcuts-field-param="' + field + '"]')
      buttons.forEach(btn => btn.classList.remove('selected'))
      if (event.currentTarget && event.currentTarget.classList) {
        event.currentTarget.classList.add('selected')
      }
    } catch (e) {
      // ignore DOM errors
    }
  }
}
