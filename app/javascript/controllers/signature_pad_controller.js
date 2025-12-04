import { Controller } from "@hotwired/stimulus"

// Captures pointer/touch strokes on a canvas element and outputs a PNG data URI.
export default class extends Controller {
  static targets = ["canvas", "input"]
  static values = {
    background: { type: String, default: "#0f172a" },
    pen: { type: String, default: "#fbbf24" }
  }

  connect() {
    this.canvas = this.canvasTarget
    this.input = this.hasInputTarget ? this.inputTarget : null
    this.context = this.canvas.getContext("2d")
    this.devicePixelRatio = window.devicePixelRatio || 1
    this.strokes = []
    this.currentStroke = null
    this.isDrawing = false

    this.resizeHandler = this.resizeCanvas.bind(this)
    this.startHandler = this.startStroke.bind(this)
    this.moveHandler = this.extendStroke.bind(this)
    this.endHandler = this.endStroke.bind(this)

    this.resizeCanvas()
    window.addEventListener("resize", this.resizeHandler)
    this.canvas.addEventListener("pointerdown", this.startHandler)
    this.canvas.addEventListener("pointermove", this.moveHandler)
    document.addEventListener("pointerup", this.endHandler)
    document.addEventListener("pointercancel", this.endHandler)
    document.addEventListener("pointerleave", this.endHandler)
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler)
    this.canvas.removeEventListener("pointerdown", this.startHandler)
    this.canvas.removeEventListener("pointermove", this.moveHandler)
    document.removeEventListener("pointerup", this.endHandler)
    document.removeEventListener("pointercancel", this.endHandler)
    document.removeEventListener("pointerleave", this.endHandler)
  }

  clear() {
    this.strokes = []
    this.currentStroke = null
    this.paintBackground()
    this.updateInput(null)
  }

  undo() {
    if (this.strokes.length === 0) return

    this.strokes.pop()
    this.paintBackground()
    this.redrawStrokes()
    this.updateInput(this.canvas.toDataURL("image/png"))
  }

  resizeCanvas() {
    const rect = this.canvas.getBoundingClientRect()
    this.canvas.width = rect.width * this.devicePixelRatio
    this.canvas.height = rect.height * this.devicePixelRatio
    this.context.setTransform(1, 0, 0, 1, 0, 0)
    this.context.scale(this.devicePixelRatio, this.devicePixelRatio)
    this.context.lineWidth = 2.5
    this.context.lineJoin = "round"
    this.context.lineCap = "round"
    this.paintBackground()
    this.redrawStrokes()
    this.updateInput(this.strokes.length ? this.canvas.toDataURL("image/png") : null)
  }

  startStroke(event) {
    event.preventDefault()
    this.isDrawing = true
    this.currentStroke = [this.pointFromEvent(event)]
    this.strokes.push(this.currentStroke)
    this.drawDot(this.currentStroke[0])
  }

  extendStroke(event) {
    if (!this.isDrawing) return

    event.preventDefault()
    const point = this.pointFromEvent(event)
    const lastPoint = this.currentStroke[this.currentStroke.length - 1]
    this.currentStroke.push(point)
    this.drawSegment(lastPoint, point)
  }

  endStroke() {
    if (!this.isDrawing) return

    this.isDrawing = false
    this.currentStroke = null
    this.updateInput(this.canvas.toDataURL("image/png"))
  }

  pointFromEvent(event) {
    const rect = this.canvas.getBoundingClientRect()
    return {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top
    }
  }

  drawDot(point) {
    this.context.save()
    this.context.fillStyle = this.penValue
    this.context.beginPath()
    this.context.arc(point.x, point.y, 1.5, 0, Math.PI * 2)
    this.context.fill()
    this.context.restore()
  }

  drawSegment(from, to) {
    this.context.save()
    this.context.strokeStyle = this.penValue
    this.context.beginPath()
    this.context.moveTo(from.x, from.y)
    this.context.lineTo(to.x, to.y)
    this.context.stroke()
    this.context.restore()
  }

  paintBackground() {
    this.context.save()
    this.context.fillStyle = this.backgroundValue
    const width = this.canvas.width / this.devicePixelRatio
    const height = this.canvas.height / this.devicePixelRatio
    this.context.fillRect(0, 0, width, height)
    this.context.restore()
  }

  redrawStrokes() {
    if (this.strokes.length === 0) return

    this.strokes.forEach((stroke) => {
      for (let i = 1; i < stroke.length; i += 1) {
        this.drawSegment(stroke[i - 1], stroke[i])
      }
      if (stroke.length === 1) {
        this.drawDot(stroke[0])
      }
    })
  }

  updateInput(value) {
    if (!this.input) return

    this.input.value = value
  }
}
