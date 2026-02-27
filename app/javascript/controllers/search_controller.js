import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "menu", "items", "empty"]

  connect() {
    this.debounceTimer = null
    this.suggestionAbortController = null

    this.boundInputHandler = this.update.bind(this)
    this.boundFocusHandler = this.open.bind(this)
    this.boundKeydownHandler = this.handleEnter.bind(this)
    this.boundIconClickHandler = this.search.bind(this)
    this.boundOutsideClickHandler = this.handleOutsideClick.bind(this)
    this.boundRepositionHandler = this.repositionMenu.bind(this)
    this.boundItemsClickHandler = this.handleItemClick.bind(this)

    const input = this.inputElement()
    if (input) {
      input.addEventListener("input", this.boundInputHandler)
      input.addEventListener("focus", this.boundFocusHandler)
      input.addEventListener("keydown", this.boundKeydownHandler)
    }

    const icon = this.searchIconElement()
    if (icon) icon.addEventListener("click", this.boundIconClickHandler)

    const items = this.itemsElement()
    if (items) items.addEventListener("click", this.boundItemsClickHandler)

    document.addEventListener("click", this.boundOutsideClickHandler)
    window.addEventListener("resize", this.boundRepositionHandler)
    window.addEventListener("scroll", this.boundRepositionHandler, true)

    this.resetMenu()
  }

  disconnect() {
    this.abortSuggestionRequest()
    if (this.debounceTimer) clearTimeout(this.debounceTimer)

    const input = this.inputElement()
    if (input) {
      input.removeEventListener("input", this.boundInputHandler)
      input.removeEventListener("focus", this.boundFocusHandler)
      input.removeEventListener("keydown", this.boundKeydownHandler)
    }

    const icon = this.searchIconElement()
    if (icon) icon.removeEventListener("click", this.boundIconClickHandler)

    const items = this.itemsElement()
    if (items) items.removeEventListener("click", this.boundItemsClickHandler)

    document.removeEventListener("click", this.boundOutsideClickHandler)
    window.removeEventListener("resize", this.boundRepositionHandler)
    window.removeEventListener("scroll", this.boundRepositionHandler, true)
  }

  open() {
    const input = this.inputElement()
    if (!input) return

    const query = this.normalizedQuery(input.value)
    if (query.length > 0) this.fetchTaskSuggestions(query)
  }

  update() {
    const input = this.inputElement()
    if (!input) return

    const query = this.normalizedQuery(input.value)
    if (query.length === 0) {
      this.resetMenu()
      return
    }

    this.fetchTaskSuggestions(query)
  }

  search(event) {
    if (event) event.preventDefault()

    const input = this.inputElement()
    if (!input) return

    const query = this.normalizedQuery(input.value)
    if (query.length === 0) return

    const url = new URL("/tasks", window.location.origin)
    url.searchParams.set("search", query)
    window.location.href = url.toString()
  }

  handleEnter(event) {
    if (event.key === "Escape") {
      this.hideMenu()
      return
    }

    if (event.key !== "Enter") return

    const first = this.itemsElement()?.querySelector("button[data-search-url]")
    if (first) {
      event.preventDefault()
      window.location.href = first.dataset.searchUrl
      return
    }

    this.search(event)
  }

  handleOutsideClick(event) {
    if (this.element.contains(event.target)) return
    this.hideMenu()
  }

  handleItemClick(event) {
    const button = event.target.closest("button[data-search-url]")
    if (!button) return

    event.preventDefault()
    const url = button.dataset.searchUrl
    if (url) window.location.href = url
  }

  fetchTaskSuggestions(query) {
    const items = this.itemsElement()
    if (!items) return

    if (this.debounceTimer) clearTimeout(this.debounceTimer)
    this.abortSuggestionRequest()

    const empty = this.emptyElement()
    if (empty) empty.classList.add("hidden")

    items.innerHTML = `
      <div class="rounded-xl px-3 py-2 text-left text-sm text-slate-300">
        Searching tasks for <span class="font-semibold text-white">${this.escapeHtml(query)}</span>...
      </div>
    `
    this.showMenu()

    this.debounceTimer = setTimeout(async () => {
      this.suggestionAbortController = new AbortController()
      const requestUrl = new URL("/tasks.json", window.location.origin)
      requestUrl.searchParams.set("search", query)

      try {
        const response = await fetch(requestUrl.toString(), {
          method: "GET",
          credentials: "same-origin",
          headers: { Accept: "application/json" },
          signal: this.suggestionAbortController.signal
        })

        if (!response.ok) throw new Error(`search failed: ${response.status}`)

        const input = this.inputElement()
        if (!input || this.normalizedQuery(input.value) !== query) return

        const payload = await response.json()
        const tasks = Array.isArray(payload) ? payload : []
        this.renderTaskSuggestions(tasks, query)
      } catch (error) {
        if (error.name === "AbortError") return
        this.renderTaskFallback(query)
      }
    }, 180)
  }

  renderTaskSuggestions(tasks, query) {
    const items = this.itemsElement()
    if (!items) return

    const empty = this.emptyElement()
    if (tasks.length === 0) {
      items.innerHTML = ""
      if (empty) empty.classList.remove("hidden")
      this.renderTaskFallback(query, true)
      return
    }

    if (empty) empty.classList.add("hidden")

    items.innerHTML = tasks.map((task) => {
      const barcode = this.escapeHtml(task.barcode || `#${task.id}`)
      const customer = this.escapeHtml(task.customer_name || "-")
      const status = this.escapeHtml(task.status || "unknown")
      const packageType = this.escapeHtml(task.package_type || "")
      const url = this.escapeHtml(task.url || `/tasks/${task.id}`)

      return `
        <button type="button" class="rounded-xl px-3 py-2 text-left text-sm text-white hover:bg-white/5" data-search-url="${url}">
          <span class="inline-flex items-center gap-1 rounded-md border border-yellow-400/40 bg-yellow-400/20 px-2 py-0.5 text-xs shadow-sm shadow-yellow-500/20"><span class="font-semibold text-yellow-200">${barcode}</span> <span class="text-slate-300">· ${status}</span></span>
          <div class="font-semibold">${customer}</div>
          <div class="text-xs text-slate-400">${packageType}</div>
        </button>
      `
    }).join("")

    this.showMenu()
  }

  renderTaskFallback(query, append = false) {
    const items = this.itemsElement()
    if (!items) return

    const fallbackUrl = new URL("/tasks", window.location.origin)
    fallbackUrl.searchParams.set("search", query)

    const markup = `
      <button type="button" class="rounded-xl px-3 py-2 text-left text-sm text-white hover:bg-white/5" data-search-url="${this.escapeHtml(fallbackUrl.toString())}">
        <span class="text-xs text-slate-400">Task Search</span>
        <div class="font-semibold">Search tasks for “${this.escapeHtml(query)}”</div>
      </button>
    `

    if (append) {
      items.insertAdjacentHTML("beforeend", markup)
    } else {
      items.innerHTML = markup
    }

    this.showMenu()
  }

  showMenu() {
    const menu = this.menuElement()
    if (!menu) return

    this.repositionMenu()
    menu.classList.remove("hidden")
    menu.style.display = "block"
  }

  hideMenu() {
    const menu = this.menuElement()
    if (!menu) return

    menu.classList.add("hidden")
    menu.style.display = "none"
  }

  repositionMenu() {
    const menu = this.menuElement()
    const input = this.inputElement()
    if (!menu || !input) return

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

  resetMenu() {
    const items = this.itemsElement()
    if (items) items.innerHTML = ""

    const empty = this.emptyElement()
    if (empty) empty.classList.add("hidden")

    this.hideMenu()
  }

  normalizedQuery(raw) {
    return String(raw || "").replace(/^\|+/, "").trim()
  }

  inputElement() {
    return this.hasInputTarget ? this.inputTarget : this.element.querySelector("input[data-search-target='input']")
  }

  menuElement() {
    return this.hasMenuTarget ? this.menuTarget : this.element.querySelector("[data-search-target='menu']")
  }

  itemsElement() {
    if (this.hasItemsTarget) return this.itemsTarget

    const menu = this.menuElement()
    if (!menu) return null

    let items = menu.querySelector("[data-search-target='items']")
    if (!items) {
      items = document.createElement("div")
      items.className = "flex flex-col gap-1"
      items.setAttribute("data-search-target", "items")
      menu.prepend(items)
    }

    return items
  }

  emptyElement() {
    if (this.hasEmptyTarget) return this.emptyTarget

    const menu = this.menuElement()
    if (!menu) return null

    return menu.querySelector("[data-search-target='empty']")
  }

  searchIconElement() {
    return this.element.querySelector("svg[data-action*='search#search']")
  }

  abortSuggestionRequest() {
    if (this.suggestionAbortController) {
      this.suggestionAbortController.abort()
      this.suggestionAbortController = null
    }
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
