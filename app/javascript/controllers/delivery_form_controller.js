import { Controller } from "@hotwired/stimulus"

const ERROR_CLASSES = [
  "border-red-500",
  "focus:border-red-500",
  "focus:ring-1",
  "focus:ring-red-500",
  "bg-red-900/10"
]

export default class extends Controller {
  static targets = ["field", "error", "submit"]

  connect() {
    this.submitted = false
    this.handleFieldEvent = this.handleFieldEvent.bind(this)

    this.fieldTargets.forEach((field) => {
      if (!field.dataset.deliveryFormDefaultClass) {
        field.dataset.deliveryFormDefaultClass = (field.className || "").trim()
      }

      field.addEventListener("input", this.handleFieldEvent)
      field.addEventListener("change", this.handleFieldEvent)
      field.addEventListener("blur", this.handleFieldEvent)
    })

    this.applyServerErrors()
    const result = this.validateForm({ showErrors: this.submitted })
    if (!this.submitted) {
      this.updateSubmitButton(result.valid)
    }
  }

  disconnect() {
    this.fieldTargets.forEach((field) => {
      field.removeEventListener("input", this.handleFieldEvent)
      field.removeEventListener("change", this.handleFieldEvent)
      field.removeEventListener("blur", this.handleFieldEvent)
    })
  }

  submit(event) {
    this.submitted = true
    const { valid } = this.validateForm({ showErrors: true })
    if (!valid) {
      event.preventDefault()
      event.stopImmediatePropagation()
      this.focusFirstInvalid()
    }
  }

  handleFieldEvent(event) {
    const showErrors = this.submitted || event.type !== "input"
    const { valid } = this.validateForm({ showErrors })
    if (!this.submitted) {
      this.updateSubmitButton(valid)
    }
  }

  validateForm({ showErrors = true } = {}) {
    const results = this.buildValidationResults()
    const invalidFields = []

    results.forEach((result, field) => {
      if (!result.valid) {
        invalidFields.push(field)
      }
    })

    if (showErrors) {
      this.updateFieldDom(results)
    }

    this.lastInvalidFields = invalidFields
    this.updateSubmitButton(invalidFields.length === 0)

    return { valid: invalidFields.length === 0, invalidFields }
  }

  buildValidationResults() {
    const results = new Map()

    this.fieldTargets.forEach((field) => {
      results.set(field, { valid: true, message: "" })
    })

    this.fieldTargets.forEach((field) => {
      const result = results.get(field)
      const required = field.dataset.deliveryFormRequired === "true" || field.required
      const optional = field.dataset.deliveryFormOptional === "true"
      const value = this.fieldValue(field)

      if (required && this.isBlank(value)) {
        result.valid = false
        result.message =
          field.dataset.deliveryFormRequiredMessage || "This field is required."
      }
    })

    this.applyUniqueGroupRules(results)
    this.applyServerErrorState(results)

    return results
  }

  applyUniqueGroupRules(results) {
    const groups = {}

    this.fieldTargets.forEach((field) => {
      const group = field.dataset.deliveryFormUniqueGroup
      if (!group) return

      const value = this.fieldValue(field)
      if (this.isBlank(value)) return

      groups[group] ||= {}
      groups[group][value] ||= []
      groups[group][value].push(field)
    })

    Object.values(groups).forEach((groupValues) => {
      Object.values(groupValues).forEach((fields) => {
        if (fields.length <= 1) return

        const message =
          fields[0].dataset.deliveryFormUniqueMessage ||
          "Each selection in this group must be unique."

        fields.forEach((field) => {
          const result = results.get(field)
          if (result && result.valid) {
            result.valid = false
            result.message = message
          }
        })
      })
    })
  }

  applyServerErrorState(results) {
    this.errorTargets.forEach((error) => {
      const present = error.dataset.deliveryFormErrorPresent === "true"
      if (!present) return

      const name = error.dataset.deliveryFormErrorName
      if (!name) return

      const field = this.fieldTargets.find(
        (candidate) => candidate.dataset.deliveryFormFieldName === name
      )

      if (!field) return

      const result = results.get(field)
      if (result) {
        result.valid = false
        result.message = error.textContent.trim()
      }
    })
  }

  updateFieldDom(results) {
    results.forEach((result, field) => {
      if (result.valid) {
        this.clearError(field)
      } else {
        this.showError(field, result.message)
      }
    })
  }

  showError(field, message) {
    const baseClass = (field.dataset.deliveryFormDefaultClass || "").trim()
    if (baseClass) {
      field.className = baseClass
    }

    field.classList.remove("border-gray-600", "focus:border-yellow-400", "focus:ring-0")
    field.classList.add(...ERROR_CLASSES)

    const errorElement = this.errorElementFor(field)
    if (!errorElement) return

    if (message && message.trim().length > 0) {
      errorElement.textContent = message
    }

    errorElement.classList.remove("hidden")
    errorElement.dataset.deliveryFormErrorPresent = "true"
  }

  clearError(field) {
    const baseClass = (field.dataset.deliveryFormDefaultClass || "").trim()
    if (baseClass) {
      field.className = baseClass
    }

    const errorElement = this.errorElementFor(field)
    if (!errorElement) return

    errorElement.textContent = ""
    errorElement.classList.add("hidden")
    errorElement.dataset.deliveryFormErrorPresent = "false"
  }

  updateSubmitButton(valid) {
    this.submitTargets.forEach((button) => {
      button.disabled = !valid
      button.setAttribute("aria-disabled", String(!valid))
      button.classList.toggle("opacity-60", !valid)
      button.classList.toggle("cursor-not-allowed", !valid)
    })
  }

  focusFirstInvalid() {
    const target = (this.lastInvalidFields || [])[0]
    if (target) {
      target.focus({ preventScroll: false })
      return
    }

    const fallback = this.fieldTargets.find((field) =>
      field.classList.contains("border-red-500")
    )
    fallback?.focus({ preventScroll: false })
  }

  applyServerErrors() {
    let hasServerErrors = false
    this.errorTargets.forEach((error) => {
      const present = error.dataset.deliveryFormErrorPresent === "true"
      if (!present) return

      const name = error.dataset.deliveryFormErrorName
      const field = this.fieldTargets.find(
        (candidate) => candidate.dataset.deliveryFormFieldName === name
      )

      if (field) {
        this.showError(field, error.textContent.trim())
        hasServerErrors = true
      }
    })

    if (hasServerErrors) {
      this.submitted = true
    }
  }

  fieldValue(field) {
    if (field.type === "file") {
      return field.files && field.files.length > 0 ? field.files.length : ""
    }

    if (field.tagName === "SELECT") {
      return field.value
    }

    return (field.value || "").trim()
  }

  isBlank(value) {
    if (value === null || value === undefined) return true
    if (typeof value === "number") return false
    if (Array.isArray(value)) return value.length === 0
    const trimmed = value.toString().trim()
    return trimmed.length === 0
  }

  errorElementFor(field) {
    const name = field.dataset.deliveryFormFieldName
    return this.errorTargets.find(
      (element) => element.dataset.deliveryFormErrorName === name
    )
  }
}
