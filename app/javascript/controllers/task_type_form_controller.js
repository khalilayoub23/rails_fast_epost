import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["taskType", "section"]

  connect() {
    this.toggle()
  }

  toggle() {
    const type = this.taskTypeTarget?.value
    this.sectionTargets.forEach((section) => {
      const types = (section.dataset.taskTypes || "").split(",").map((value) => value.trim()).filter(Boolean)
      if (types.length === 0) return

      const show = types.includes(type)
      if (show) {
        section.classList.remove("hidden")
        // Notify any delivery-flatpickr controllers inside the section to refresh
        try {
          const targets = section.querySelectorAll('[data-controller]')
          targets.forEach((el) => {
            if ((el.dataset.controller || '').includes('delivery-flatpickr')) {
              try { el.dispatchEvent(new CustomEvent('delivery-flatpickr:refresh')) } catch (e) {}
            }
          })
        } catch (e) {}
      } else {
        section.classList.add("hidden")
      }

      // Toggle required attributes for inputs that are conditionally required
      const controls = section.querySelectorAll('input[data-required-when-visible], select[data-required-when-visible], textarea[data-required-when-visible]')
      controls.forEach((control) => {
        if (show) {
          control.setAttribute('required', 'true')
          control.setAttribute('aria-required', 'true')
          control.removeAttribute('disabled')
        } else {
          control.removeAttribute('required')
          control.removeAttribute('aria-required')
          // keep fields disabled when hidden to avoid browser blocking submission
          control.setAttribute('disabled', 'true')
        }
      })
    })
  }
}
