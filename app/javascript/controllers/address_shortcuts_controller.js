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
  }
}
