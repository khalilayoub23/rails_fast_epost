import { Controller } from "@hotwired/stimulus"

// Controls UI preferences: direction (LTR/RTL) and theme (dark/light)
export default class extends Controller {
  static targets = ["rtlButton", "darkButton", "rtlIcon", "darkIcon"]

  connect() {
    // Read stored prefs
    const dir = localStorage.getItem("ui.direction") || "ltr"
    const dark = localStorage.getItem("ui.dark") === "true"

    this.applyDirection(dir)
    this.applyDark(dark)
  }

  toggleRtl() {
    const current = document.documentElement.getAttribute("dir") === "rtl" ? "rtl" : "ltr"
    const next = current === "rtl" ? "ltr" : "rtl"
    this.applyDirection(next)
    localStorage.setItem("ui.direction", next)
  }

  toggleDark() {
    const next = !document.documentElement.classList.contains("dark")
    this.applyDark(next)
    localStorage.setItem("ui.dark", String(next))
  }

  applyDirection(dir) {
    document.documentElement.setAttribute("dir", dir)
    // Optional: update button label/icon state
    if (this.hasRtlIconTarget) {
      this.rtlIconTarget.textContent = dir === "rtl" ? "format_textdirection_l_to_r" : "format_textdirection_r_to_l"
    }
  }

  applyDark(dark) {
    document.documentElement.classList.toggle("dark", dark)
    if (this.hasDarkIconTarget) {
      this.darkIconTarget.textContent = dark ? "light_mode" : "dark_mode"
    }
  }
}
