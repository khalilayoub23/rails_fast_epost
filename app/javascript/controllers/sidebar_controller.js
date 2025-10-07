import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const el = document.getElementById("sidebar")
    if (!el) return
    // TailAdmin mobile sidebar slides in/out using translate classes
    if (el.classList.contains("-translate-x-full")) {
      el.classList.remove("-translate-x-full")
      el.classList.add("translate-x-0")
    } else {
      el.classList.add("-translate-x-full")
      el.classList.remove("translate-x-0")
    }
  }
}
