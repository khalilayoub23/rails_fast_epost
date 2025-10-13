// app/javascript/controllers/sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
export default class extends Controller {
  static values = {
    url: String,
    attribute: { type: String, default: "position" },
    animation: { type: Number, default: 150 }
  }

  connect() {
    console.log("Sortable controller connected")
    this.sortable = Sortable.create(this.element, {
      animation: this.animationValue,
      handle: ".drag-handle", // Only drag from handle
      ghostClass: "sortable-ghost", // Class for ghost element
      chosenClass: "sortable-chosen", // Class for chosen element
      dragClass: "sortable-drag", // Class for dragged element
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }

  async onEnd(event) {
    // Get the ID of the moved item
    const itemId = event.item.dataset.sortableId
    
    // Calculate new position (1-indexed)
    const newPosition = event.newIndex + 1
    
    // Don't update if position didn't change
    if (event.oldIndex === event.newIndex) return

    try {
      const response = await fetch(this.urlValue.replace(":id", itemId), {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: JSON.stringify({
          [this.attributeValue]: newPosition
        })
      })

      if (!response.ok) {
        // Revert the change if it failed
        this.sortable.option("disabled", true)
        
        // Restore original order
        if (event.oldIndex < event.newIndex) {
          event.to.insertBefore(event.item, event.to.children[event.oldIndex])
        } else {
          event.to.insertBefore(event.item, event.to.children[event.oldIndex + 1])
        }
        
        this.sortable.option("disabled", false)
        
        // Show error notification
        this.showError("Failed to update order")
      } else {
        // Process Turbo Stream response if any
        const text = await response.text()
        if (text) {
          Turbo.renderStreamMessage(text)
        }
        
        // Show success notification
        this.showSuccess("Order updated successfully")
      }
    } catch (error) {
      console.error("Sortable update error:", error)
      this.showError("Failed to update order")
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  showSuccess(message) {
    this.dispatch("sort:success", { detail: { message } })
  }

  showError(message) {
    this.dispatch("sort:error", { detail: { message } })
  }
}
