import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "select", "filename", "enabled", "status"]
  static values = {
    filename: String
  }

  connect() {
    this.sync()
  }

  toggle() {
    this.sync()
  }

  select() {
    this.updateFilename()
  }

  sync() {
    const enabled = this.toggleTarget?.checked
    if (this.hasEnabledTarget) {
      this.enabledTarget.value = enabled ? "1" : "0"
    }
    this.updateFilename()
    this.updateStatus(enabled)
    this.updateKnob(enabled)
  }

  updateFilename() {
    if (!this.hasFilenameTarget) return
    const name = this.filenameValue || ""
    this.filenameTarget.textContent = name && name.trim() ? name.trim() : ""
  }

  updateKnob(enabled) {
    const knob = this.element.querySelector("span.pointer-events-none")
    const isRtl = document.documentElement.dir === "rtl"
    if (!knob) return

    // Use class toggles instead of inline styles (CSP-safe)
    if (enabled) {
      knob.classList.remove("poa-knob-left")
      knob.classList.add("poa-knob-right")
    } else {
      knob.classList.remove("poa-knob-right")
      knob.classList.add("poa-knob-left")
    }

    // RTL adjustments via CSS selectors will handle direction-specific transforms
  }

  updateStatus(enabled) {
    if (!this.hasStatusTarget) return
    if (enabled) {
      this.statusTarget.textContent = "Attached"
      this.statusTarget.className = "inline-flex items-center rounded-full border border-emerald-400/30 bg-emerald-500/10 px-3 py-1 text-xs font-semibold text-emerald-200"
    } else {
      this.statusTarget.textContent = "Not attached"
      this.statusTarget.className = "inline-flex items-center rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs font-semibold text-slate-300"
    }
  }
}
