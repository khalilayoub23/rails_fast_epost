import { Controller } from "@hotwired/stimulus"

// Renders a simple inline SVG bar chart matching TailAdmin style, CSP-safe.
export default class extends Controller {
  static targets = ["chartContainer"]
  static values = {
    seriesA: Object,
    seriesB: Object
  }

  connect() {
    this.setActivePeriod("month")
  }

  update(event) {
    const period = event.params.period || "month"
    this.setActivePeriod(period, event.currentTarget)
  }

  setActivePeriod(period, clickedButton = null) {
    const normalizedPeriod = ["day", "week", "month"].includes(period) ? period : "month"

    const buttons = this.element.querySelectorAll('button[data-charts-period-param]')
    buttons.forEach(btn => {
      btn.className = "px-3 py-1 text-xs font-medium text-slate-300 hover:bg-white/10 hover:text-white rounded transition-colors"
      btn.setAttribute("aria-pressed", "false")
    })

    const activeButton = clickedButton || this.element.querySelector(`button[data-charts-period-param="${normalizedPeriod}"]`)
    if (activeButton) {
      activeButton.className = "rounded bg-yellow-400 px-3 py-1 text-xs font-medium text-black shadow-lg hover:bg-yellow-500 transition-colors"
      activeButton.setAttribute("aria-pressed", "true")
    }

    this.renderChart(normalizedPeriod)
  }

  renderChart(period) {
    const fallback = {
      day: [120, 380, 220, 180, 260, 140, 80, 300, 190, 280, 220, 110],
      week: [180, 260, 140, 80, 300, 190, 280, 220, 110, 120, 380, 220],
      month: [220, 110, 120, 380, 220, 180, 260, 140, 80, 300, 190, 280]
    }
    const fallbackB = {
      day: [100, 320, 200, 150, 210, 120, 60, 260, 160, 250, 190, 90],
      week: [150, 210, 120, 60, 260, 160, 250, 190, 90, 100, 320, 200],
      month: [190, 90, 100, 320, 200, 150, 210, 120, 60, 260, 160, 250]
    }

    const normalizedPeriod = ["day", "week", "month"].includes(period) ? period : "month"
    const a = (this.seriesAValue && this.seriesAValue[normalizedPeriod]) || fallback[normalizedPeriod]
    const b = (this.seriesBValue && this.seriesBValue[normalizedPeriod]) || fallbackB[normalizedPeriod]

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
    const maxVal = Math.max(...a, ...b, 1)

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
