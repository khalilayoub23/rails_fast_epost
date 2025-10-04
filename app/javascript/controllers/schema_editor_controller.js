import { Controller } from "@hotwired/stimulus"

// data-controller="schema-editor"
// Expects a canvas area (div) to click to add fields, and supports dragging fields
export default class extends Controller {
  static targets = ["canvas", "output"]

  connect() {
    this.fields = this.loadInitial()
    this.render()
    this.canvasTarget.addEventListener("click", this.addField)
  }

  disconnect() {
    this.canvasTarget.removeEventListener("click", this.addField)
  }

  loadInitial() {
    try {
      const json = this.outputTarget.value
      const parsed = JSON.parse(json || "{}")
      return parsed.fields || []
    } catch (e) {
      return []
    }
  }

  render() {
    this.canvasTarget.innerHTML = ""
    this.fields.forEach((f, idx) => {
      const el = document.createElement("div")
      el.className = "schema-field"
      el.textContent = f.name || `field_${idx+1}`
      el.style.position = "absolute"
      el.style.left = (f.x || 50) + "px"
      el.style.top = (f.y || 50) + "px"
      el.style.padding = "4px 8px"
      el.style.background = "#eef"
      el.style.border = "1px solid #99c"
      el.draggable = true
      el.addEventListener("dragstart", (ev) => {
        ev.dataTransfer.setData("text/plain", idx)
      })
      this.canvasTarget.appendChild(el)
    })

    this.canvasTarget.addEventListener("dragover", (ev) => ev.preventDefault())
    this.canvasTarget.addEventListener("drop", (ev) => {
      ev.preventDefault()
      const idx = parseInt(ev.dataTransfer.getData("text/plain"), 10)
      const rect = this.canvasTarget.getBoundingClientRect()
      this.fields[idx].x = ev.clientX - rect.left
      this.fields[idx].y = ev.clientY - rect.top
      this.updateOutput()
      this.render()
    })
  }

  addField = (ev) => {
    const rect = this.canvasTarget.getBoundingClientRect()
    const x = ev.clientX - rect.left
    const y = ev.clientY - rect.top
    this.fields.push({ name: `field_${this.fields.length+1}`, x, y, font_size: 12 })
    this.updateOutput()
    this.render()
  }

  updateOutput() {
    const obj = { title: "Untitled", fields: this.fields }
    this.outputTarget.value = JSON.stringify(obj)
  }
}
