import { Controller } from "@hotwired/stimulus"

// Renders a simple inline SVG bar chart matching TailAdmin style, CSP-safe.
export default class extends Controller {
  static values = {
    seriesA: Array,
    seriesB: Array
  }

  connect() {
    const a = this.seriesAValue?.length ? this.seriesAValue : [120, 380, 220, 180, 260, 140, 80, 300, 190, 280, 220, 110]
    const b = this.seriesBValue?.length ? this.seriesBValue : [100, 320, 200, 150, 210, 120, 60, 260, 160, 250, 190, 90]
    this.element.innerHTML = this.renderBars(a, b)
  }

  renderBars(a, b) {
    const width = 760
    const height = 260
    const padLeft = 24
    const padBottom = 24
    const barGroupGap = 28
    const monthGap = 24
    const barWidth = 10
    const maxVal = Math.max(...a, ...b, 400)

    let x = padLeft
    let bars = ''
    for (let i = 0; i < 12; i++) {
      const ah = Math.round((a[i] / maxVal) * (height - padBottom - 20))
      const bh = Math.round((b[i] / maxVal) * (height - padBottom - 20))
      const yBase = height - padBottom
      // series A (primary)
      bars += `<rect x="${x}" y="${yBase - ah}" width="${barWidth}" height="${ah}" rx="3" class="fill-primary" />`
      // series B (secondary)
      bars += `<rect x="${x + barWidth + 4}" y="${yBase - bh}" width="${barWidth}" height="${bh}" rx="3" class="fill-secondary" />`
      x += barGroupGap + monthGap
    }

    return `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg" class="overflow-visible">
      <g>${bars}</g>
    </svg>`
  }
}
