import { Controller } from "@hotwired/stimulus"

// A minimal modal controller to toggle visibility without external libs
export default class extends Controller {
  static targets = ["backdrop", "dialog"]

  open(event) {
    event?.preventDefault()
    this.backdropTarget.classList.remove("hidden")
    this.backdropTarget.classList.add("flex")
  }

  close(event) {
    event?.preventDefault()
    this.backdropTarget.classList.add("hidden")
    this.backdropTarget.classList.remove("flex")
  }
}
