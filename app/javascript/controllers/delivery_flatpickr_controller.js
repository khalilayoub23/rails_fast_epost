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
    // navigation handler (Turbo) and scroll handler
    this._boundTurbo = () => { try { this._closeCalendar() } catch (e) {} }
    this._boundScroll = () => { try { this._closeCalendar() } catch (e) {} }
    try { document.addEventListener('turbo:before-visit', this._boundTurbo) } catch (e) {}
    try { window.addEventListener('scroll', this._boundScroll, { passive: true }) } catch (e) {}
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
        onOpen: this.onOpen.bind(this),
        onChange: this.onChange.bind(this),
        onClose: this.onClose.bind(this),
        static: true
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

  onOpen(selectedDates, dateStr, instance) {
    // add a document click listener to close when clicking outside
    this._boundDocClick = (ev) => { try { this._onDocumentClick(ev) } catch (e) {} }
    try { document.addEventListener('click', this._boundDocClick) } catch (e) {}
  }

  _onDocumentClick(ev) {
    try {
      if (!this.fp || !this.fp.calendarContainer) return
      const cal = this.fp.calendarContainer
      const target = ev.target
      if (cal.contains(target) || this.element.contains(target) || this.inputTarget.contains && this.inputTarget.contains(target)) {
        return
      }
      this._closeCalendar()
    } catch (e) {}
  }

  _closeCalendar() {
    try { if (this.fp && typeof this.fp.close === 'function') this.fp.close() } catch (e) {}
  }

  disconnect() {
    if (this.fp) {
      try { this.fp.destroy() } catch (e) {}
    }
    try { document.removeEventListener('turbo:before-visit', this._boundTurbo) } catch (e) {}
    try { window.removeEventListener('scroll', this._boundScroll, { passive: true }) } catch (e) {}
    try { document.removeEventListener('click', this._boundDocClick) } catch (e) {}
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
    try { if (this.fp && typeof this.fp.close === 'function') this.fp.close() } catch (e) {}
    // additional fallback in case the close needs to run after event loop
    try { setTimeout(() => { if (this.fp && typeof this.fp.close === 'function') this.fp.close() }, 0) } catch (e) {}
  }

  _writeHiddenFromDate(dt) {
    try {
      const year = dt.getFullYear()
      const month = String(dt.getMonth() + 1).padStart(2, "0")
      const day = String(dt.getDate()).padStart(2, "0")
      const hour = String(dt.getHours()).padStart(2, "0")
      const minute = String(dt.getMinutes()).padStart(2, "0")
      this.hiddenTarget.value = `${year}-${month}-${day}T${hour}:${minute}`
    } catch (e) {
      try { this.hiddenTarget.value = this.fp.input.value } catch (ee) {}
    }
  }
}
