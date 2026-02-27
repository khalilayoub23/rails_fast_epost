// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "stripe_checkout"
import "google_autocomplete"

// Turbo configuration
import { Turbo } from "@hotwired/turbo-rails"

// Configure Turbo Drive
Turbo.session.drive = true

// Add progress bar configuration
document.addEventListener("turbo:before-fetch-request", (event) => {
  // Custom loading indicator can be added here
})

document.addEventListener("turbo:load", () => {
  // Re-initialize components after Turbo navigation
  console.log("Turbo loaded")
})

// Handle form submissions
document.addEventListener("turbo:submit-end", (event) => {
  if (event.detail.success) {
    // Form submitted successfully
  }
})

// Handle errors
document.addEventListener("turbo:frame-missing", (event) => {
  event.preventDefault()
  console.error("Turbo Frame missing:", event.detail)
})

const topbarSearchInit = () => {
  const root = document.querySelector('[data-controller~="search"]')
  if (!root) return
  if (root.dataset.searchFallbackBound === "true") return

  const input = root.querySelector('[data-search-target="input"]')
  const menu = root.querySelector('[data-search-target="menu"]')
  const items = root.querySelector('[data-search-target="items"]')
  const empty = root.querySelector('[data-search-target="empty"]')
  if (!input || !menu || !items) return

  root.dataset.searchFallbackBound = "true"

  let debounceTimer = null
  let abortController = null

  const escapeHtml = (value) => String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;")

  const normalizeQuery = (value) => String(value || "").replace(/^\|+/, "").trim()

  const hideMenu = () => {
    menu.classList.add("hidden")
    menu.style.display = "none"
  }

  const positionMenu = () => {
    const rect = input.getBoundingClientRect()
    menu.style.position = "fixed"
    menu.style.left = `${Math.max(12, rect.left)}px`
    menu.style.top = `${rect.bottom + 8}px`
    menu.style.width = `${Math.max(240, rect.width)}px`
    menu.style.right = "auto"
    menu.style.zIndex = "10000"
    menu.style.maxHeight = "60vh"
    menu.style.overflowY = "auto"
  }

  const showMenu = () => {
    positionMenu()
    menu.classList.remove("hidden")
    menu.style.display = "block"
  }

  const renderFallback = (query) => {
    const url = new URL("/tasks", window.location.origin)
    url.searchParams.set("search", query)
    items.innerHTML = `
      <button type="button" class="rounded-xl px-3 py-2 text-left text-sm text-white hover:bg-white/5" data-search-url="${escapeHtml(url.toString())}">
        <span class="text-xs text-slate-400">Task Search</span>
        <div class="font-semibold">Search tasks for “${escapeHtml(query)}”</div>
      </button>
    `
    showMenu()
  }

  const fetchSuggestions = (query) => {
    if (abortController) abortController.abort()
    if (debounceTimer) clearTimeout(debounceTimer)
    if (empty) empty.classList.add("hidden")

    items.innerHTML = '<div class="rounded-xl px-3 py-2 text-left text-sm text-slate-300">Searching tasks...</div>'
    showMenu()

    debounceTimer = setTimeout(async () => {
      abortController = new AbortController()
      const requestUrl = new URL("/tasks.json", window.location.origin)
      requestUrl.searchParams.set("search", query)

      try {
        const response = await fetch(requestUrl.toString(), {
          method: "GET",
          credentials: "same-origin",
          headers: { Accept: "application/json" },
          signal: abortController.signal
        })

        if (!response.ok) throw new Error(`search failed: ${response.status}`)

        const currentQuery = normalizeQuery(input.value)
        if (currentQuery !== query) return

        const tasks = await response.json()
        if (!Array.isArray(tasks) || tasks.length === 0) {
          items.innerHTML = ""
          if (empty) empty.classList.remove("hidden")
          renderFallback(query)
          return
        }

        if (empty) empty.classList.add("hidden")
        items.innerHTML = tasks.map((task) => {
          const barcode = escapeHtml(task.barcode || `#${task.id}`)
          const customer = escapeHtml(task.customer_name || "-")
          const status = escapeHtml(task.status || "unknown")
          const packageType = escapeHtml(task.package_type || "")
          const url = escapeHtml(task.url || `/tasks/${task.id}`)

          return `
            <button type="button" class="rounded-xl px-3 py-2 text-left text-sm text-white hover:bg-white/5" data-search-url="${url}">
              <span class="inline-flex items-center gap-1 rounded-md border border-yellow-400/40 bg-yellow-400/20 px-2 py-0.5 text-xs shadow-sm shadow-yellow-500/20"><span class="font-semibold text-yellow-200">${barcode}</span> <span class="text-slate-300">· ${status}</span></span>
              <div class="font-semibold">${customer}</div>
              <div class="text-xs text-slate-400">${packageType}</div>
            </button>
          `
        }).join("")

        showMenu()
      } catch (error) {
        if (error.name === "AbortError") return
        renderFallback(query)
      }
    }, 180)
  }

  input.addEventListener("input", () => {
    const query = normalizeQuery(input.value)
    if (query.length === 0) {
      items.innerHTML = ""
      if (empty) empty.classList.add("hidden")
      hideMenu()
      return
    }
    fetchSuggestions(query)
  })

  input.addEventListener("focus", () => {
    const query = normalizeQuery(input.value)
    if (query.length > 0) fetchSuggestions(query)
  })

  input.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      hideMenu()
      return
    }

    if (event.key !== "Enter") return

    const first = items.querySelector("button[data-search-url]")
    if (first) {
      event.preventDefault()
      window.location.href = first.dataset.searchUrl
      return
    }

    const query = normalizeQuery(input.value)
    if (query.length === 0) return

    const url = new URL("/tasks", window.location.origin)
    url.searchParams.set("search", query)
    window.location.href = url.toString()
  })

  items.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-search-url]")
    if (!button) return
    event.preventDefault()
    window.location.href = button.dataset.searchUrl
  })

  document.addEventListener("click", (event) => {
    if (root.contains(event.target)) return
    hideMenu()
  })

  window.addEventListener("resize", positionMenu)
  window.addEventListener("scroll", positionMenu, true)
  hideMenu()
}

document.addEventListener("turbo:load", topbarSearchInit)
if (document.readyState !== "loading") topbarSearchInit()
