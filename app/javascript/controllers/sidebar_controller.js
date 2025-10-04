import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const el = document.getElementById("sidebar")
    if (!el) return
    el.classList.toggle("hidden")
    el.classList.toggle("fixed")
    el.classList.toggle("inset-y-0")
    el.classList.toggle("z-40")
    el.classList.toggle("w-64")
  }
}
