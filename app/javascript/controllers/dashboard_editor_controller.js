import { Controller } from "@hotwired/stimulus"

// Enables drag-and-drop reordering of dashboard widgets
export default class extends Controller {
  static targets = ["container"]
  static values = { saveUrl: String }

  connect() {
    this.editing = false
    this.refreshElements()
    this.disableDrag()
  }

  disconnect() {
    this.draggables?.forEach(el => {
      el.removeEventListener('dragstart', this.onDragStart)
      el.removeEventListener('dragover', this.onDragOver)
      el.removeEventListener('drop', this.onDrop)
    })
  }

  onDragStart = (e) => {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', e.currentTarget.dataset.widgetId)
  }

  onDragOver = (e) => {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'move'
  }

  onDrop = (e) => {
    e.preventDefault()
    const draggedId = e.dataTransfer.getData('text/plain')
    const target = e.currentTarget
    const container = this.containerTarget
    const draggedEl = container.querySelector(`[data-widget-id="${draggedId}"]`)
    if (!draggedEl || draggedEl === target) return

    // Insert dragged before target
    container.insertBefore(draggedEl, target)
    // refresh internal refs since DOM order changed
    this.refreshElements()
    this.save()
  }

  toggleEdit() {
    this.editing = !this.editing
    this.editing ? this.enableDrag() : this.disableDrag()
  }

  enableDrag() {
    this.draggables.forEach(el => {
      el.setAttribute('draggable', 'true')
      el.addEventListener('dragstart', this.onDragStart)
      el.addEventListener('dragover', this.onDragOver)
      el.addEventListener('drop', this.onDrop)
    })
    this.toolbars.forEach(tb => tb.classList.remove('hidden'))
  }

  disableDrag() {
    this.draggables.forEach(el => {
      el.setAttribute('draggable', 'false')
      el.removeEventListener('dragstart', this.onDragStart)
      el.removeEventListener('dragover', this.onDragOver)
      el.removeEventListener('drop', this.onDrop)
    })
    this.toolbars?.forEach(tb => tb.classList.add('hidden'))
  }

  changeSpan(event) {
    const select = event.currentTarget
    const wrapper = select.closest('[data-widget-id]')
    if (!wrapper) return
    const prev = (wrapper.dataset.span || '').trim()
    const next = select.value.trim()
    if (prev) {
      prev.split(/\s+/).forEach(c => c && wrapper.classList.remove(c))
    }
    next.split(/\s+/).forEach(c => c && wrapper.classList.add(c))
    wrapper.dataset.span = next
    this.save()
  }

  save() {
    const widgets = Array.from(this.containerTarget.querySelectorAll('[data-widget-id]'))
    const order = widgets.map(el => el.dataset.widgetId)
    const spans = widgets.map(el => ({ id: el.dataset.widgetId, span: el.dataset.span || '' }))
    const body = JSON.stringify({ order, spans })
    fetch(this.saveUrlValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body
    }).then(r => {
      if (!r.ok) throw new Error('Failed to save layout')
    }).catch(err => console.error(err))
  }

  refreshElements() {
    this.draggables = Array.from(this.containerTarget.querySelectorAll('[data-widget-id]'))
    this.toolbars = Array.from(this.containerTarget.querySelectorAll('[data-role="widget-toolbar"]'))
  }
}
