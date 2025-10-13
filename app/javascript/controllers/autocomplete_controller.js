import { Controller } from "@hotwired/stimulus"

// Autocomplete controller for search and select inputs
export default class extends Controller {
  static targets = ["input", "results", "hiddenInput"]
  static values = {
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.timeout = null
    this.abortController = null
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
    if (this.abortController) this.abortController.abort()
  }

  search() {
    const query = this.inputTarget.value

    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }

    // Debounce the search
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.fetchResults(query)
    }, 300)
  }

  async fetchResults(query) {
    // Abort previous request
    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    try {
      const url = `${this.urlValue}?q=${encodeURIComponent(query)}`
      const response = await fetch(url, {
        signal: this.abortController.signal,
        headers: {
          "Accept": "application/json"
        }
      })

      if (!response.ok) throw new Error("Network response was not ok")

      const data = await response.json()
      this.displayResults(data)
    } catch (error) {
      if (error.name !== "AbortError") {
        console.error("Autocomplete error:", error)
      }
    }
  }

  displayResults(data) {
    if (!data || data.length === 0) {
      this.hideResults()
      return
    }

    this.resultsTarget.innerHTML = data.map(item => `
      <div class="px-4 py-2 hover:bg-whiter dark:hover:bg-boxdark cursor-pointer"
           data-action="click->autocomplete#select"
           data-id="${item.id}"
           data-value="${item.name || item.text}">
        ${item.name || item.text}
      </div>
    `).join("")

    this.showResults()
  }

  select(event) {
    const id = event.currentTarget.dataset.id
    const value = event.currentTarget.dataset.value

    this.inputTarget.value = value
    
    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = id
    }

    this.hideResults()

    // Dispatch custom event
    this.element.dispatchEvent(new CustomEvent("autocomplete:selected", {
      detail: { id, value },
      bubbles: true
    }))
  }

  showResults() {
    this.resultsTarget.classList.remove("hidden")
  }

  hideResults() {
    this.resultsTarget.classList.add("hidden")
    this.resultsTarget.innerHTML = ""
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
}
