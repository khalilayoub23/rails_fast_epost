import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "nextButton", "backButton", "indicator", "paymentField"]

  connect() {
    this.currentIndex = 0
    this.showCurrent()
  }

  next(event) {
    event.preventDefault()
    if (this.currentIndex < this.stepTargets.length - 1) {
      this.currentIndex += 1
      this.showCurrent()
    }
  }

  back(event) {
    event.preventDefault()
    if (this.currentIndex > 0) {
      this.currentIndex -= 1
      this.showCurrent()
    }
  }

  showCurrent() {
    this.stepTargets.forEach((el, idx) => {
      el.classList.toggle("hidden", idx !== this.currentIndex)
    })

    if (this.hasBackButtonTarget) {
      this.backButtonTarget.classList.toggle("hidden", this.currentIndex === 0)
    }

    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.classList.toggle(
        "hidden",
        this.currentIndex >= this.stepTargets.length - 1,
      )
    }

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.textContent = `Step ${this.currentIndex + 1} of ${this.stepTargets.length}`
    }

    if (this.hasPaymentFieldTarget) {
      const enablePayment = this.currentIndex >= this.stepTargets.length - 1
      this.paymentFieldTargets.forEach((el) => {
        el.disabled = !enablePayment

        if (el.dataset && el.dataset.paymentRequired === "true") {
          el.required = enablePayment
        }
      })
    }
  }
}
