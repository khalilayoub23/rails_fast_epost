// app/javascript/controllers/presence_controller.js
import { Controller } from "@hotwired/stimulus"
import { consumer } from "../channels/consumer"

// Connects to data-controller="presence"
export default class extends Controller {
  static values = {
    channel: String,
    userId: Number,
    userName: String
  }

  connect() {
    console.log("Presence controller connected")
    this.subscribe()
    this.startHeartbeat()
  }

  disconnect() {
    this.unsubscribe()
    this.stopHeartbeat()
  }

  subscribe() {
    this.subscription = consumer.subscriptions.create(
      {
        channel: this.channelValue,
        user_id: this.userIdValue
      },
      {
        connected: () => {
          console.log("Connected to presence channel")
          this.broadcastPresence("online")
        },

        disconnected: () => {
          console.log("Disconnected from presence channel")
          this.broadcastPresence("offline")
        },

        received: (data) => {
          this.handlePresenceUpdate(data)
        }
      }
    )
  }

  unsubscribe() {
    if (this.subscription) {
      this.broadcastPresence("offline")
      this.subscription.unsubscribe()
    }
  }

  broadcastPresence(status) {
    if (this.subscription) {
      this.subscription.perform("update_presence", {
        user_id: this.userIdValue,
        user_name: this.userNameValue,
        status: status,
        timestamp: new Date().toISOString()
      })
    }
  }

  handlePresenceUpdate(data) {
    const { user_id, user_name, status, users_online } = data

    // Update online users count
    this.updateOnlineCount(users_online)

    // Update user status indicator
    const indicator = document.querySelector(`[data-user-id="${user_id}"]`)
    if (indicator) {
      this.updateUserIndicator(indicator, status)
    }

    // Show notification for important users
    if (status === "online" && user_id !== this.userIdValue) {
      this.showNotification(`${user_name} is now online`)
    }

    // Dispatch custom event for other controllers
    this.dispatch("presence:update", {
      detail: { user_id, user_name, status, users_online }
    })
  }

  updateOnlineCount(count) {
    const counters = document.querySelectorAll("[data-presence-count]")
    counters.forEach(counter => {
      counter.textContent = count
      counter.classList.toggle("hidden", count === 0)
    })
  }

  updateUserIndicator(element, status) {
    const dot = element.querySelector(".presence-dot")
    if (!dot) return

    // Remove all status classes
    dot.classList.remove("bg-green-500", "bg-gray-400", "bg-yellow-500", "bg-red-500")

    // Add appropriate status class
    switch (status) {
      case "online":
        dot.classList.add("bg-green-500")
        dot.title = "Online"
        break
      case "away":
        dot.classList.add("bg-yellow-500")
        dot.title = "Away"
        break
      case "busy":
        dot.classList.add("bg-red-500")
        dot.title = "Busy"
        break
      default:
        dot.classList.add("bg-gray-400")
        dot.title = "Offline"
    }

    // Animate the change
    dot.classList.add("animate-pulse")
    setTimeout(() => {
      dot.classList.remove("animate-pulse")
    }, 1000)
  }

  startHeartbeat() {
    // Send presence update every 30 seconds
    this.heartbeatInterval = setInterval(() => {
      this.broadcastPresence("online")
    }, 30000)
  }

  stopHeartbeat() {
    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval)
    }
  }

  showNotification(message) {
    // Dispatch to notification controller
    const event = new CustomEvent("notification:show", {
      detail: {
        message: message,
        type: "info",
        duration: 3000
      }
    })
    document.dispatchEvent(event)
  }

  // Manual status updates
  setOnline() {
    this.broadcastPresence("online")
  }

  setAway() {
    this.broadcastPresence("away")
  }

  setBusy() {
    this.broadcastPresence("busy")
  }

  setOffline() {
    this.broadcastPresence("offline")
  }
}
