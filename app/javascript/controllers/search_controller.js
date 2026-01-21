import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Listen for Command+K or Ctrl+K
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
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
    
    if (query.length === 0) {
      alert('Please enter a search term')
      return
    }

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
