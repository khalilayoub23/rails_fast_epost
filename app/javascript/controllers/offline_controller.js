// app/javascript/controllers/offline_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="offline"
export default class extends Controller {
  static targets = ["indicator", "banner", "syncStatus"]
  static values = {
    checkInterval: { type: Number, default: 30000 }, // 30 seconds
    syncOnReconnect: { type: Boolean, default: true }
  }

  connect() {
    console.log("Offline controller connected")
    this.isOnline = navigator.onLine
    this.pendingActions = this.loadPendingActions()
    
    this.setupEventListeners()
    this.updateUI()
    this.startHealthCheck()
  }

  disconnect() {
    this.stopHealthCheck()
    window.removeEventListener("online", this.handleOnline)
    window.removeEventListener("offline", this.handleOffline)
  }

  setupEventListeners() {
    this.handleOnline = this.goOnline.bind(this)
    this.handleOffline = this.goOffline.bind(this)
    
    window.addEventListener("online", this.handleOnline)
    window.addEventListener("offline", this.handleOffline)
  }

  goOnline() {
    console.log("Connection restored")
    this.isOnline = true
    this.updateUI()
    this.showNotification("Connection restored", "success")
    
    if (this.syncOnReconnectValue && this.pendingActions.length > 0) {
      this.syncPendingActions()
    }
  }

  goOffline() {
    console.log("Connection lost")
    this.isOnline = false
    this.updateUI()
    this.showNotification("You're offline. Changes will be synced when reconnected.", "warning")
  }

  updateUI() {
    // Update indicator
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.toggle("online", this.isOnline)
      this.indicatorTarget.classList.toggle("offline", !this.isOnline)
      this.indicatorTarget.title = this.isOnline ? "Online" : "Offline"
    }

    // Show/hide offline banner
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.toggle("hidden", this.isOnline)
    }

    // Update sync status
    this.updateSyncStatus()

    // Dispatch event
    this.dispatch(this.isOnline ? "online" : "offline", {
      detail: { pendingActions: this.pendingActions.length }
    })
  }

  updateSyncStatus() {
    if (this.hasSyncStatusTarget && this.pendingActions.length > 0) {
      this.syncStatusTarget.textContent = `${this.pendingActions.length} pending action${this.pendingActions.length > 1 ? 's' : ''}`
      this.syncStatusTarget.classList.remove("hidden")
    } else if (this.hasSyncStatusTarget) {
      this.syncStatusTarget.classList.add("hidden")
    }
  }

  // Queue form submissions for later sync
  queueAction(event) {
    if (this.isOnline) return // Let it go through normally

    event.preventDefault()
    
    const form = event.target.closest("form")
    if (!form) return

    const action = {
      id: this.generateId(),
      timestamp: new Date().toISOString(),
      method: form.method.toUpperCase(),
      url: form.action,
      data: new FormData(form),
      formData: this.serializeFormData(form)
    }

    this.pendingActions.push(action)
    this.savePendingActions()
    this.updateSyncStatus()

    this.showNotification("Action queued for sync", "info")
  }

  serializeFormData(form) {
    const formData = new FormData(form)
    const serialized = {}
    
    for (const [key, value] of formData.entries()) {
      if (serialized[key]) {
        // Handle multiple values (like checkboxes)
        if (!Array.isArray(serialized[key])) {
          serialized[key] = [serialized[key]]
        }
        serialized[key].push(value)
      } else {
        serialized[key] = value
      }
    }
    
    return serialized
  }

  async syncPendingActions() {
    if (!this.isOnline || this.pendingActions.length === 0) return

    this.showNotification(`Syncing ${this.pendingActions.length} actions...`, "info")

    const results = {
      success: 0,
      failed: 0,
      errors: []
    }

    // Process actions in order
    for (const action of [...this.pendingActions]) {
      try {
        const response = await this.replayAction(action)
        
        if (response.ok) {
          // Remove from pending
          this.pendingActions = this.pendingActions.filter(a => a.id !== action.id)
          results.success++
        } else {
          results.failed++
          results.errors.push({
            action: action,
            error: `HTTP ${response.status}`
          })
        }
      } catch (error) {
        results.failed++
        results.errors.push({
          action: action,
          error: error.message
        })
      }
    }

    this.savePendingActions()
    this.updateSyncStatus()

    // Show results
    if (results.success > 0) {
      this.showNotification(`Successfully synced ${results.success} action${results.success > 1 ? 's' : ''}`, "success")
    }

    if (results.failed > 0) {
      console.error("Sync errors:", results.errors)
      this.showNotification(`Failed to sync ${results.failed} action${results.failed > 1 ? 's' : ''}`, "error")
    }

    // Reload page if everything synced successfully
    if (results.success > 0 && results.failed === 0) {
      setTimeout(() => {
        Turbo.visit(window.location.href, { action: "replace" })
      }, 1000)
    }
  }

  async replayAction(action) {
    const formData = new FormData()
    
    for (const [key, value] of Object.entries(action.formData)) {
      if (Array.isArray(value)) {
        value.forEach(v => formData.append(key, v))
      } else {
        formData.append(key, value)
      }
    }

    return fetch(action.url, {
      method: action.method,
      headers: {
        "X-CSRF-Token": this.csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    })
  }

  manualSync() {
    if (!this.isOnline) {
      this.showNotification("Cannot sync while offline", "warning")
      return
    }

    this.syncPendingActions()
  }

  clearPending() {
    if (confirm(`Clear ${this.pendingActions.length} pending actions?`)) {
      this.pendingActions = []
      this.savePendingActions()
      this.updateSyncStatus()
      this.showNotification("Pending actions cleared", "info")
    }
  }

  // Health check to verify actual connectivity
  startHealthCheck() {
    this.healthCheckInterval = setInterval(() => {
      this.checkConnection()
    }, this.checkIntervalValue)
  }

  stopHealthCheck() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval)
    }
  }

  async checkConnection() {
    try {
      const response = await fetch("/health", {
        method: "HEAD",
        cache: "no-cache"
      })

      const wasOnline = this.isOnline
      this.isOnline = response.ok

      // Trigger events if status changed
      if (wasOnline && !this.isOnline) {
        this.goOffline()
      } else if (!wasOnline && this.isOnline) {
        this.goOnline()
      }
    } catch (error) {
      if (this.isOnline) {
        this.goOffline()
      }
    }
  }

  // LocalStorage helpers
  loadPendingActions() {
    try {
      const stored = localStorage.getItem("offline_pending_actions")
      return stored ? JSON.parse(stored) : []
    } catch (error) {
      console.error("Failed to load pending actions:", error)
      return []
    }
  }

  savePendingActions() {
    try {
      localStorage.setItem("offline_pending_actions", JSON.stringify(this.pendingActions))
    } catch (error) {
      console.error("Failed to save pending actions:", error)
    }
  }

  generateId() {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  }

  showNotification(message, type = "info") {
    const event = new CustomEvent("notification:show", {
      detail: { message, type, duration: 5000 }
    })
    document.dispatchEvent(event)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
