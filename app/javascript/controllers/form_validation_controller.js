import { Controller } from "@hotwired/stimulus"

// Provides client-side validation feedback for forms. Highlights invalid inputs,
// displays inline error messages, and blocks submission until the form passes
// basic checks. Pairs with server-rendered error messages so styling is
// consistent across both validation paths.
export default class extends Controller {
  static targets = ["input", "message"]

  connect() {
    this.handleSubmit = this.handleSubmit.bind(this)
    this.handleInput = this.handleInput.bind(this)

    this.element.addEventListener("submit", this.handleSubmit)

    this.inputTargets.forEach((input) => {
      if (!input.dataset.formValidationOriginalClass) {
        const base = input.dataset.formValidationBaseClass || input.className
        input.dataset.formValidationOriginalClass = (base || "").trim()
      }

      input.addEventListener("input", this.handleInput)
      input.addEventListener("change", this.handleInput)
    })

    this.initializeServerErrors()
  }

  disconnect() {
    this.element.removeEventListener("submit", this.handleSubmit)
    this.inputTargets.forEach((input) => {
      input.removeEventListener("input", this.handleInput)
      input.removeEventListener("change", this.handleInput)
    })
  }

  handleSubmit(event) {
    const invalidFields = this.validateForm()

    if (invalidFields.length > 0) {
      event.preventDefault()
      invalidFields[0].focus({ preventScroll: false })
    }
  }

  handleInput(event) {
    this.validateField(event.target)
  }

  validateForm() {
    const invalid = []

    this.inputTargets.forEach((input) => {
      if (!this.validateField(input)) {
        invalid.push(input)
      }
    })

    return invalid
  }

  validateField(input) {
    const rules = (input.dataset.formValidationRules || "")
      .split(" ")
      .map((rule) => rule.trim())
      .filter(Boolean)

    if (rules.length === 0) {
      this.clearError(input)
      return true
    }

    for (const rule of rules) {
      switch (rule) {
        case "presence":
          if (this.blank(input)) {
            this.showError(
              input,
              input.dataset.formValidationMessagePresence || "This field is required."
            )
            return false
          }
          break
        default:
          break
      }
    }

    this.clearError(input)
    return true
  }

  blank(input) {
    const value = input.value ?? ""

    if (input.type === "checkbox" || input.type === "radio") {
      return !input.checked
    }

    if (input.tagName === "SELECT") {
      return value === "" || value === null
    }

    return value.trim() === ""
  }

  showError(input, message) {
    this.applyErrorStyles(input)

    const messageElement = this.findMessageElement(input)
    if (!messageElement) return

    messageElement.textContent = message
    messageElement.classList.remove("hidden")
    messageElement.dataset.formValidationState = "visible"
    messageElement.dataset.serverMessage = "false"
  }

  clearError(input) {
    this.removeErrorStyles(input)

    const messageElement = this.findMessageElement(input)
    if (!messageElement) return

    messageElement.textContent = ""
    messageElement.classList.add("hidden")
    messageElement.dataset.formValidationState = "hidden"
    messageElement.dataset.serverMessage = "false"
  }

  applyErrorStyles(input) {
    const baseClass = this.baseClassFor(input)
    input.className = baseClass

    input.classList.remove("border-gray-600", "focus:border-yellow-400", "focus:ring-0")
    input.classList.add(
      "border-red-500",
      "focus:border-red-500",
      "focus:ring-1",
      "focus:ring-red-500",
      "bg-red-900/10"
    )
  }

  removeErrorStyles(input) {
    const baseClass = this.baseClassFor(input)
    input.className = baseClass
  }

  baseClassFor(input) {
    return (input.dataset.formValidationOriginalClass || input.dataset.formValidationBaseClass || input.className || "").trim()
  }

  findMessageElement(input) {
    const fieldId = input.dataset.formValidationField || input.id
    return this.messageTargets.find((message) => message.dataset.field === fieldId)
  }

  initializeServerErrors() {
    this.messageTargets.forEach((message) => {
      if (message.dataset.formValidationState === "visible") {
        const field = this.inputTargets.find((input) => {
          const fieldId = input.dataset.formValidationField || input.id
          return fieldId === message.dataset.field
        })

        if (field) {
          this.applyErrorStyles(field)
        }
      }
    })
  }
}
