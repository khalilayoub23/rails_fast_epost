// app/javascript/controllers/realtime_notifications_controller.js
import { Controller } from "@hotwired/stimulus"
import { consumer } from "../channels/consumer"

// Connects to data-controller="realtime-notifications"
export default class extends Controller {
  static targets = ["badge", "list", "dropdown"]
  static values = {
    userId: Number,
    unreadCount: { type: Number, default: 0 }
  }

  connect() {
    console.log("Realtime notifications controller connected")
    this.subscribe()
    this.updateBadge()
  }

  disconnect() {
    this.unsubscribe()
  }

  subscribe() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: "NotificationsChannel",
        user_id: this.userIdValue
      },
      {
        connected: () => {
          console.log("Connected to notifications channel")
        },

        disconnected: () => {
          console.log("Disconnected from notifications channel")
        },

        received: (data) => {
          this.handleNotification(data)
        }
      }
    )
  }

  unsubscribe() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  handleNotification(data) {
    const { notification, action } = data

    switch (action) {
      case "new":
        this.addNotification(notification)
        this.showToast(notification)
        this.playSound()
        break
      case "mark_read":
        this.markAsRead(notification.id)
        break
      case "mark_all_read":
        this.markAllAsRead()
        break
      case "delete":
        this.removeNotification(notification.id)
        break
    }

    this.updateBadge()
  }

  addNotification(notification) {
    // Increment unread count
    this.unreadCountValue++

    // Add to list
    if (this.hasListTarget) {
      const html = this.buildNotificationHTML(notification)
      this.listTarget.insertAdjacentHTML("afterbegin", html)

      // Limit to 50 notifications
      const items = this.listTarget.querySelectorAll(".notification-item")
      if (items.length > 50) {
        items[items.length - 1].remove()
      }
    }
  }

  buildNotificationHTML(notification) {
    const unreadClass = notification.read_at ? "" : "bg-blue-50 dark:bg-blue-900/20"
    const icon = this.getIconForType(notification.notification_type)

    return `
      <div class="notification-item ${unreadClass} border-b border-stroke dark:border-dark-3 hover:bg-gray-1 dark:hover:bg-dark-2 transition-colors"
           data-notification-id="${notification.id}">
        <a href="${notification.url || '#'}" 
           class="flex items-start gap-3 px-4 py-3"
           data-action="click->realtime-notifications#markAsReadAndVisit"
           data-notification-id="${notification.id}">
          
          <span class="material-icons text-2xl text-primary flex-shrink-0 mt-1">
            ${icon}
          </span>
          
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-dark dark:text-white mb-1">
              ${notification.title}
            </p>
            <p class="text-sm text-body-color dark:text-dark-6 mb-1">
              ${notification.body}
            </p>
            <p class="text-xs text-body-color dark:text-dark-6">
              ${this.timeAgo(notification.created_at)}
            </p>
          </div>

          ${!notification.read_at ? `
            <span class="flex-shrink-0 w-2 h-2 bg-primary rounded-full mt-2"></span>
          ` : ''}
        </a>
      </div>
    `
  }

  getIconForType(type) {
    const icons = {
      task: "assignment",
      payment: "payment",
      customer: "person",
      form: "description",
      comment: "comment",
      mention: "alternate_email",
      system: "notifications",
      success: "check_circle",
      warning: "warning",
      error: "error"
    }
    return icons[type] || "notifications"
  }

  timeAgo(timestamp) {
    const seconds = Math.floor((new Date() - new Date(timestamp)) / 1000)
    
    const intervals = {
      year: 31536000,
      month: 2592000,
      week: 604800,
      day: 86400,
      hour: 3600,
      minute: 60
    }

    for (const [unit, secondsInUnit] of Object.entries(intervals)) {
      const interval = Math.floor(seconds / secondsInUnit)
      if (interval >= 1) {
        return `${interval} ${unit}${interval > 1 ? 's' : ''} ago`
      }
    }

    return "just now"
  }

  markAsReadAndVisit(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    if (notificationId) {
      this.markAsRead(notificationId)
    }
  }

  async markAsRead(notificationId) {
    try {
      await fetch(`/notifications/${notificationId}/mark_read`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      // Update UI
      const item = this.listTarget.querySelector(`[data-notification-id="${notificationId}"]`)
      if (item) {
        item.classList.remove("bg-blue-50", "dark:bg-blue-900/20")
        const dot = item.querySelector(".bg-primary.rounded-full")
        if (dot) dot.remove()
      }

      // Decrement unread count
      if (this.unreadCountValue > 0) {
        this.unreadCountValue--
        this.updateBadge()
      }
    } catch (error) {
      console.error("Failed to mark notification as read:", error)
    }
  }

  async markAllAsRead() {
    try {
      await fetch("/notifications/mark_all_read", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      // Update UI
      const items = this.listTarget.querySelectorAll(".notification-item")
      items.forEach(item => {
        item.classList.remove("bg-blue-50", "dark:bg-blue-900/20")
        const dot = item.querySelector(".bg-primary.rounded-full")
        if (dot) dot.remove()
      })

      // Reset unread count
      this.unreadCountValue = 0
      this.updateBadge()
    } catch (error) {
      console.error("Failed to mark all as read:", error)
    }
  }

  removeNotification(notificationId) {
    const item = this.listTarget.querySelector(`[data-notification-id="${notificationId}"]`)
    if (item) {
      item.remove()
    }
  }

  updateBadge() {
    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = this.unreadCountValue
      this.badgeTarget.classList.toggle("hidden", this.unreadCountValue === 0)
    }
  }

  showToast(notification) {
    const event = new CustomEvent("notification:show", {
      detail: {
        message: notification.body,
        type: "info",
        duration: 5000
      }
    })
    document.dispatchEvent(event)
  }

  playSound() {
    // Only play if user has interacted with page (browser requirement)
    if (document.visibilityState === "visible") {
      const audio = new Audio("/sounds/notification.mp3")
      audio.volume = 0.3
      audio.play().catch(() => {
        // Ignore errors (no user interaction yet)
      })
    }
  }

  toggleDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle("hidden")
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
