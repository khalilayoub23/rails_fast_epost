import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const el = document.getElementById("sidebar")
    if (!el) return
    
    // Check if we are on desktop (lg breakpoint is usually 1024px)
    if (window.innerWidth >= 1024) {
      // On desktop, sidebar is static by default. We can toggle 'hidden' to show/hide it.
      // Or better, toggle a class that collapses it.
      // Since the sidebar has 'lg:static', we can toggle 'lg:hidden' or just 'hidden'.
      el.classList.toggle("hidden")
    } else {
      // TailAdmin mobile sidebar slides in/out using translate classes
      // Handle RTL support
      // We read the hidden class from the data attribute to support both LTR (-translate-x-full) and RTL (translate-x-full)
      const hiddenClass = el.dataset.hiddenClass || "-translate-x-full"
      
      if (el.classList.contains(hiddenClass)) {
        el.classList.remove(hiddenClass)
        el.classList.add("translate-x-0")
      } else {
        el.classList.add(hiddenClass)
        el.classList.remove("translate-x-0")
      }
    }
  }
}
