import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    newCustomerUrl: String
  }

  maybeAdd(event) {
    if (event.target.value !== "__new__") {
      return
    }

    if (this.hasNewCustomerUrlValue && this.newCustomerUrlValue) {
      window.location.href = this.newCustomerUrlValue
    }

    event.target.value = ""
    event.target.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
