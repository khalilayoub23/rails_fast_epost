// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="infinite-scroll"
export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = {
    url: String,
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false }
  }

  connect() {
    console.log("Infinite scroll controller connected")
    this.createObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  createObserver() {
    const options = {
      root: null, // viewport
      rootMargin: "100px", // Start loading 100px before bottom
      threshold: 0.1
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && !this.loadingValue) {
          this.loadMore()
        }
      })
    }, options)

    // Observe the pagination element
    if (this.hasPaginationTarget) {
      this.observer.observe(this.paginationTarget)
    }
  }

  async loadMore() {
    if (this.loadingValue) return

    this.loadingValue = true
    this.showLoadingIndicator()

    try {
      const nextPage = this.pageValue + 1
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("page", nextPage)

      const response = await fetch(url, {
        headers: {
          Accept: "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        
        // Check if there's content
        if (html.trim().length > 0) {
          // Append the new content
          Turbo.renderStreamMessage(html)
          this.pageValue = nextPage
        } else {
          // No more content, hide pagination
          this.hidePagination()
        }
      }
    } catch (error) {
      console.error("Failed to load more:", error)
    } finally {
      this.loadingValue = false
      this.hideLoadingIndicator()
    }
  }

  showLoadingIndicator() {
    if (this.hasPaginationTarget) {
      this.paginationTarget.innerHTML = `
        <div class="flex justify-center items-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          <span class="ml-3 text-body-color dark:text-dark-6">Loading more...</span>
        </div>
      `
    }
  }

  hideLoadingIndicator() {
    if (this.hasPaginationTarget) {
      this.paginationTarget.innerHTML = ""
    }
  }

  hidePagination() {
    if (this.hasPaginationTarget) {
      this.paginationTarget.innerHTML = `
        <div class="flex justify-center items-center py-8 text-body-color dark:text-dark-6">
          <span class="material-icons mr-2">check_circle</span>
          <span>All items loaded</span>
        </div>
      `
      
      // Disconnect observer
      if (this.observer) {
        this.observer.disconnect()
      }
    }
  }
}
