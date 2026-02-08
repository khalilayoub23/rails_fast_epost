import { Controller } from "@hotwired/stimulus"

// Renders a simple inline SVG bar chart matching TailAdmin style, CSP-safe.
export default class extends Controller {
  static targets = ["chartContainer", "seriesAValue", "seriesBValue"]
  static values = {
    seriesA: Object,
    seriesB: Object,
    labels: Object,
    currency: String,
    emptyText: String
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
    const a = this.normalizeSeries((this.seriesAValue && this.seriesAValue[normalizedPeriod]) || fallback[normalizedPeriod])
    const b = this.normalizeSeries((this.seriesBValue && this.seriesBValue[normalizedPeriod]) || fallbackB[normalizedPeriod])

    if (this.isEmptySeries(a, b)) {
      const emptyText = this.emptyTextValue || "No data for this period yet."
      this.chartContainerTarget.innerHTML = `<div class="py-10 text-center text-sm text-slate-400">${emptyText}</div>`
      this.updateTotals(0, 0)
      return
    }

    const containerWidth = this.chartContainerTarget.clientWidth || 720
    const width = Math.max(containerWidth, 560)

    const labels = this.normalizeLabels((this.labelsValue && this.labelsValue[normalizedPeriod]) || this.defaultLabels(normalizedPeriod))
    this.chartContainerTarget.innerHTML = this.renderBars(a, b, width, labels)
    this.updateTotals(this.sumSeries(a), this.sumSeries(b))
  }

  updateTotals(totalA, totalB) {
    if (this.hasSeriesAValueTarget) {
      this.seriesAValueTarget.textContent = this.formatCurrency(totalA)
    }
    if (this.hasSeriesBValueTarget) {
      this.seriesBValueTarget.textContent = this.formatNumber(totalB)
    }
  }

  sumSeries(series) {
    return (Array.isArray(series) ? series : []).reduce((sum, value) => sum + (Number(value) || 0), 0)
  }

  formatCurrency(value) {
    const currency = this.currencyValue || "USD"
    try {
      return new Intl.NumberFormat(document.documentElement.lang || undefined, {
        style: "currency",
        currency,
        maximumFractionDigits: 0
      }).format(value)
    } catch (error) {
      return `${currency} ${this.formatNumber(value)}`
    }
  }

  formatNumber(value) {
    try {
      return new Intl.NumberFormat(document.documentElement.lang || undefined, {
        maximumFractionDigits: 0
      }).format(value)
    } catch (error) {
      return String(Math.round(value))
    }
  }

  formatCompact(value) {
    try {
      return new Intl.NumberFormat(document.documentElement.lang || undefined, {
        notation: "compact",
        maximumFractionDigits: 1
      }).format(value)
    } catch (error) {
      return this.formatNumber(value)
    }
  }

  renderBars(a, b, width, labels) {
    const height = 280
    const padLeft = 44
    const padBottom = 40
    const groups = 12
    const gapBetweenBars = 4
    const available = Math.max(width - padLeft - 24, 320)
    const groupWidth = available / groups
    const barWidth = Math.max(Math.min(12, Math.floor((groupWidth - gapBetweenBars) / 2)), 6)
    const groupGap = Math.max(groupWidth - (barWidth * 2 + gapBetweenBars), 6)
    const maxVal = Math.max(...a, ...b, 1)

    let x = padLeft
    let bars = ''
    let xLabels = ''
    let grid = ''

    const gridStops = [0, 25, 50, 75, 100]
    gridStops.forEach(percent => {
      const y = height - padBottom - Math.round(((height - padBottom - 24) * percent) / 100)
      grid += `<line x1="${padLeft}" y1="${y}" x2="${width - 16}" y2="${y}" stroke="#1F2937" stroke-width="1" />`
      grid += `<text x="${padLeft - 8}" y="${y + 3}" text-anchor="end" font-size="10" fill="#64748B">${percent}%</text>`
    })

    for (let i = 0; i < groups; i++) {
      const ah = Math.round((a[i] / maxVal) * (height - padBottom - 20))
      const bh = Math.round((b[i] / maxVal) * (height - padBottom - 20))
      const yBase = height - padBottom
      // series A (primary)
      bars += `<rect x="${x}" y="${yBase - ah}" width="${barWidth}" height="${ah}" rx="3" class="fill-primary" />`
      // series B (secondary)
      bars += `<rect x="${x + barWidth + gapBetweenBars}" y="${yBase - bh}" width="${barWidth}" height="${bh}" rx="3" class="fill-secondary" />`

      const centerX = x + barWidth + gapBetweenBars / 2
      const label = labels[i] || ""
      xLabels += `<text x="${centerX}" y="${height - 10}" text-anchor="middle" font-size="10" fill="#94A3B8">${label}</text>`

      x += groupGap + barWidth * 2 + gapBetweenBars
    }

    return `<svg width="100%" height="${height}" viewBox="0 0 ${width} ${height}" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg" class="overflow-visible">
      <g>${grid}</g>
      <g>${bars}</g>
      <g>${xLabels}</g>
    </svg>`
  }

  normalizeSeries(series) {
    let values = Array.isArray(series) ? series.slice() : []
    values = values.map(value => Number(value) || 0)
    if (values.length > 12) values = values.slice(-12)
    while (values.length < 12) values.push(0)
    return values
  }

  normalizeLabels(labels) {
    let values = Array.isArray(labels) ? labels.slice() : []
    if (values.length > 12) values = values.slice(-12)
    while (values.length < 12) values.unshift("")
    return values
  }

  defaultLabels(period) {
    if (period === "month") {
      return ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    }
    return Array.from({ length: 12 }, (_, i) => String(i + 1))
  }

  isEmptySeries(a, b) {
    const total = [...a, ...b].reduce((sum, val) => sum + (Number(val) || 0), 0)
    return total === 0
  }
}
