import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "menu", "item", "empty"]

  connect() {
    // Listen for Command+K or Ctrl+K
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
  }

  open() {
    if (!this.hasMenuTarget || !this.hasInputTarget) return
    if (this.inputTarget.value.trim().length > 0) {
      this.menuTarget.classList.remove("hidden")
    }
  }

  update() {
    if (!this.hasMenuTarget || !this.hasItemTarget || !this.hasInputTarget) return

    const query = this.inputTarget.value.trim().toLowerCase()
    if (query.length === 0) {
      this.menuTarget.classList.add("hidden")
      if (this.hasEmptyTarget) this.emptyTarget.classList.add("hidden")
      this.itemTargets.forEach((item) => item.classList.add("hidden"))
      return
    }

    let matches = 0
    this.itemTargets.forEach((item) => {
      const label = item.dataset.searchLabel?.toLowerCase() || ""
      const url = item.dataset.searchUrl?.toLowerCase() || ""
      const match = label.includes(query) || url.includes(query) || url.replace("/", "").includes(query)
      if (match) {
        item.classList.remove("hidden")
        matches += 1
      } else {
        item.classList.add("hidden")
      }
    })

    if (this.hasEmptyTarget) {
      this.emptyTarget.classList.toggle("hidden", matches > 0)
    }
    this.menuTarget.classList.remove("hidden")
  }

  navigate(event) {
    const url = event.currentTarget.dataset.searchUrl
    if (url) {
      window.location.href = url
    }
  }

  disconnect() {
    if (this.boundKeydown) {
      document.removeEventListener('keydown', this.boundKeydown)
    }
  }

  handleKeydown(event) {
    // Command+K or Ctrl+K
    if ((event.metaKey || event.ctrlKey) && event.key === 'k') {
      event.preventDefault()
      this.focus()
    }
  }

  focus() {
    if (this.hasInputTarget) {
      this.inputTarget.focus()
      this.inputTarget.select()
    }
  }

  search(event) {
    if (event) event.preventDefault()
    
    const query = this.inputTarget.value.trim()
    
    if (query.length === 0) return

    // Handle different search commands
    if (query.startsWith('/')) {
      this.handleCommand(query)
    } else {
      this.performSearch(query)
    }
  }

  handleCommand(command) {
    const cmd = command.toLowerCase()
    
    // Quick navigation commands
    const routes = {
      '/dashboard': '/',
      '/tasks': '/tasks',
      '/customers': '/customers',
      '/cart': '/cart',
      '/deliveries': '/deliveries',
      '/profile': '/profile',
      '/settings': '/settings'
    }

    if (routes[cmd]) {
      window.location.href = routes[cmd]
    } else {
      alert('Unknown command. Try: /dashboard, /tasks, /customers')
    }
  }

  performSearch(query) {
    // Redirect to tasks search with query
    const url = new URL('/tasks', window.location.origin)
    url.searchParams.set('search', query)
    window.location.href = url.toString()
  }

  handleEnter(event) {
    if (event.key === 'Enter') {
      this.search(event)
    }
  }
}
