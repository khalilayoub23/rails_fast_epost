import { Controller } from "@hotwired/stimulus"

// Renders a simple inline SVG bar chart matching TailAdmin style, CSP-safe.
export default class extends Controller {
  static targets = ["chartContainer"]

  connect() {
    this.renderChart('day')
  }

  update(event) {
    // Reset all buttons style
    this.element.querySelectorAll('button').forEach(btn => {
      btn.className = "flex items-center justify-center min-w-[80px] px-3 py-2 text-xs font-medium text-gray-400 hover:bg-gray-800 hover:text-white rounded-md transition-colors leading-tight"
    })

    // Set active style
    event.currentTarget.className = "flex items-center justify-center min-w-[80px] rounded-md bg-yellow-400 px-3 py-2 text-xs font-medium text-gray-900 shadow-lg hover:bg-yellow-500 transition-colors leading-tight"

    const period = event.params.period
    this.renderChart(period)
  }

  renderChart(period) {
    let a, b
    
    if (period === 'day') {
       a = [120, 380, 220, 180, 260, 140, 80, 300, 190, 280, 220, 110]
       b = [100, 320, 200, 150, 210, 120, 60, 260, 160, 250, 190, 90]
    } else if (period === 'week') {
       a = [180, 260, 140, 80, 300, 190, 280, 220, 110, 120, 380, 220]
       b = [150, 210, 120, 60, 260, 160, 250, 190, 90, 100, 320, 200]
    } else {
       a = [220, 110, 120, 380, 220, 180, 260, 140, 80, 300, 190, 280]
       b = [190, 90, 100, 320, 200, 150, 210, 120, 60, 260, 160, 250]
    }

    this.chartContainerTarget.innerHTML = this.renderBars(a, b)
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
