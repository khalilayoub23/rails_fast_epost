import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"

export default class extends Controller {
  static targets = ["input", "hidden"]

  connect() {
    this._initFlatpickr()

    // Listen for explicit refresh events when a section becomes visible
    this.element.addEventListener('delivery-flatpickr:refresh', () => {
      this._initFlatpickr()
    })
  }

  _initFlatpickr() {
    if (!this.hasInputTarget) return
    // destroy previous instance if present
    if (this.fp) {
      try { this.fp.destroy() } catch (e) {}
      this.fp = null
    }
    try {
      this.fp = flatpickr(this.inputTarget, {
        enableTime: true,
        time_24hr: true,
        dateFormat: "Y-m-d H:i",
        allowInput: true,
        onChange: this.onChange.bind(this),
        onClose: this.onClose.bind(this),
        // Append calendar to body to avoid clipping by overflow:hidden parents
        appendTo: document.body
      })

      // Tag the calendar container so we can style it via CSS overrides
      try {
        if (this.fp && this.fp.calendarContainer) {
          this.fp.calendarContainer.classList.add('fastpost-flatpickr')
        }
      } catch (e) {}

      // initialize from hidden value if present
      if (this.hasHiddenTarget && this.hiddenTarget.value) {
        try {
          this.fp.setDate(this.hiddenTarget.value, false)
        } catch (e) {}
      }
    } catch (e) {
      // noop
    }
  }

  disconnect() {
    if (this.fp) {
      try { this.fp.destroy() } catch (e) {}
    }
  }

  open() {
    try {
      if (this.fp && typeof this.fp.open === 'function') {
        this.fp.open()
      } else if (this.hasInputTarget) {
        try { this.inputTarget.focus() } catch (e) {}
      }
    } catch (e) {}
  }

  onClose(selectedDates) {
    // onClose may be triggered after onChange; ensure hidden target reflects current value
    if (!this.hasHiddenTarget) return
    if (selectedDates && selectedDates.length) {
      this._writeHiddenFromDate(selectedDates[0])
    }
    // Trigger change so other Stimulus controllers (priority-auto) can react
    try { this.hiddenTarget.dispatchEvent(new Event('change', { bubbles: true })) } catch (e) {}
  }

  onChange(selectedDates, dateStr, instance) {
    if (!this.hasHiddenTarget) return
    if (selectedDates && selectedDates.length) {
      this._writeHiddenFromDate(selectedDates[0])
    } else {
      this.hiddenTarget.value = ""
    }
    try { this.hiddenTarget.dispatchEvent(new Event('change', { bubbles: true })) } catch (e) {}
    // Close the flatpickr instance immediately so the UI doesn't linger
    try { instance.close() } catch (e) {}
  }

  _writeHiddenFromDate(dt) {
    try {
      const iso = dt.toISOString()
      this.hiddenTarget.value = iso.slice(0,16)
    } catch (e) {
      try { this.hiddenTarget.value = this.fp.input.value } catch (ee) {}
    }
  }
}
