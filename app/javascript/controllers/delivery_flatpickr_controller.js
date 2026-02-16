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
    // reposition handler for window resize
    this._boundResize = () => { try { this._positionCalendar() } catch (e) {} }
    try { window.addEventListener('resize', this._boundResize) } catch (e) {}
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

  onOpen(selectedDates, dateStr, instance) {
    // position the calendar so it does not get clipped by viewport
    try { this._positionCalendar() } catch (e) {}
    // run again shortly after render
    try { setTimeout(() => { this._positionCalendar() }, 30) } catch (e) {}
    // add a document click listener to close when clicking outside
    this._boundDocClick = (ev) => { try { this._onDocumentClick(ev) } catch (e) {} }
    try { document.addEventListener('click', this._boundDocClick) } catch (e) {}
  }

  _positionCalendar() {
    if (!this.fp || !this.fp.calendarContainer || !this.hasInputTarget) return
    try {
      const cal = this.fp.calendarContainer
      const inp = this.inputTarget
      const inpRect = inp.getBoundingClientRect()
      // ensure calendar is measured after render
      const calRect = cal.getBoundingClientRect()
      const viewportWidth = Math.max(document.documentElement.clientWidth, window.innerWidth || 0)
      const viewportHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0)

      // preferred placement: below the input, left-aligned
      let left = inpRect.left
      let top = inpRect.bottom + 6

      // Adjust horizontal placement to keep the full calendar visible.
      // Handle RTL by aligning the calendar's right edge with the input's right edge.
      const isRTL = document.documentElement && document.documentElement.dir === 'rtl'
      if (isRTL) {
        // prefer aligning right edge of calendar with input right edge
        left = inpRect.right - calRect.width
      }

      if (left + calRect.width > viewportWidth - 8) {
        left = viewportWidth - calRect.width - 8
      }
      if (left < 8) left = 8

      // if calendar would overflow bottom, position above the input
      if (top + calRect.height > viewportHeight - 8) {
        const altTop = inpRect.top - calRect.height - 6
        if (altTop > 0) top = altTop
      }

      // apply computed position (account for page scroll)
      cal.style.position = 'absolute'
      cal.style.left = (left + window.scrollX) + 'px'
      cal.style.top = (top + window.scrollY) + 'px'
    } catch (e) {
      // ignore positioning errors
    }
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
    try { window.removeEventListener('resize', this._boundResize) } catch (e) {}
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
      const iso = dt.toISOString()
      this.hiddenTarget.value = iso.slice(0,16)
    } catch (e) {
      try { this.hiddenTarget.value = this.fp.input.value } catch (ee) {}
    }
  }
}
