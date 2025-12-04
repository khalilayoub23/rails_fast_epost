import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    if (!localStorage.getItem("cookieConsent")) {
      this.bannerTarget.classList.remove("hidden")
      // Small delay to allow display:block to apply before transition
      requestAnimationFrame(() => {
        this.bannerTarget.classList.remove("translate-y-full", "opacity-0")
      })
    }
  }

  accept() {
    localStorage.setItem("cookieConsent", "accepted")
    this.bannerTarget.classList.add("translate-y-full", "opacity-0")
    
    // Wait for transition to finish before hiding
    setTimeout(() => {
      this.bannerTarget.classList.add("hidden")
    }, 500)
  }
}
