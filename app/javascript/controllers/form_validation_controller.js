import { Controller } from "@hotwired/stimulus"

// Form validation controller
export default class extends Controller {
  static targets = ["input", "error", "submit"]
  static values = {
    required: Boolean,
    pattern: String,
    minLength: Number,
    maxLength: Number
  }

  connect() {
    this.validateOnInput()
  }

  validateOnInput() {
    this.inputTargets.forEach(input => {
      input.addEventListener("input", () => this.validateField(input))
      input.addEventListener("blur", () => this.validateField(input))
    })
  }

  validateField(input) {
    const errorElement = input.parentElement.querySelector("[data-form-validation-target='error']")
    let isValid = true
    let errorMessage = ""

    // Required validation
    if (input.required && !input.value.trim()) {
      isValid = false
      errorMessage = `${input.placeholder || "This field"} is required`
    }

    // Min length validation
    if (input.minLength && input.value.length < input.minLength && input.value.length > 0) {
      isValid = false
      errorMessage = `Minimum ${input.minLength} characters required`
    }

    // Max length validation
    if (input.maxLength && input.value.length > input.maxLength) {
      isValid = false
      errorMessage = `Maximum ${input.maxLength} characters allowed`
    }

    // Email validation
    if (input.type === "email" && input.value) {
      const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      if (!emailPattern.test(input.value)) {
        isValid = false
        errorMessage = "Please enter a valid email address"
      }
    }

    // Pattern validation
    if (input.pattern && input.value) {
      const pattern = new RegExp(input.pattern)
      if (!pattern.test(input.value)) {
        isValid = false
        errorMessage = input.title || "Invalid format"
      }
    }

    // Update UI
    if (isValid) {
      input.classList.remove("border-red-500")
      input.classList.add("border-stroke")
      if (errorElement) {
        errorElement.textContent = ""
        errorElement.classList.add("hidden")
      }
    } else {
      input.classList.add("border-red-500")
      input.classList.remove("border-stroke")
      if (errorElement) {
        errorElement.textContent = errorMessage
        errorElement.classList.remove("hidden")
      }
    }

    this.updateSubmitButton()
    return isValid
  }

  validate(event) {
    let isValid = true

    this.inputTargets.forEach(input => {
      if (!this.validateField(input)) {
        isValid = false
      }
    })

    if (!isValid) {
      event.preventDefault()
      event.stopPropagation()
    }

    return isValid
  }

  updateSubmitButton() {
    if (!this.hasSubmitTarget) return

    const allValid = this.inputTargets.every(input => {
      return !input.classList.contains("border-red-500")
    })

    if (allValid) {
      this.submitTarget.disabled = false
      this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
    } else {
      this.submitTarget.disabled = true
      this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
  }
}
