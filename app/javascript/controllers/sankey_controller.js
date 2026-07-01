import { Controller } from "@hotwired/stimulus"

// Renders a D3 Sankey money-flow diagram from @sankey_data.
// D3 v7 + d3-sankey are loaded as UMD bundles from the CDN in the view's
// content_for :head block; both attach to the global `d3` object.
//
// Expected value shape:
//   { nodes: [{ id, label, group }], links: [{ source, target, value }] }
// where group is one of "income" | "account" | "expense".
export default class extends Controller {
  static values = { data: Object }

  connect() {
    this.render()
    this.resizeObserver = new ResizeObserver(() => this.render())
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    if (this.resizeObserver) this.resizeObserver.disconnect()
  }

  render() {
    const d3 = window.d3
    const data = this.dataValue || {}
    const nodes = Array.isArray(data.nodes) ? data.nodes : []
    const links = Array.isArray(data.links) ? data.links : []

    this.element.innerHTML = ""

    if (!d3 || !d3.sankey) {
      this.placeholder("Loading money-flow chart…")
      return
    }
    if (nodes.length === 0 || links.length === 0) {
      this.placeholder("No money flow to show yet — sync your accounts to see income and spending.")
      return
    }

    const width = this.element.clientWidth || 800
    const height = 320
    const margin = { top: 8, right: 8, bottom: 8, left: 8 }

    // Fresh copies — d3-sankey mutates the arrays it's given.
    const graph = {
      nodes: nodes.map((n) => ({ ...n })),
      links: links.map((l) => ({ ...l })),
    }

    const expenseColor = d3.scaleOrdinal(d3.schemeSet3)
    const colorFor = (node) => {
      if (node.group === "income") return "#00C805"
      if (node.group === "account") return "#5AC8FA"
      return expenseColor(node.id != null ? node.id : node.label)
    }

    const svg = d3
      .select(this.element)
      .append("svg")
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("preserveAspectRatio", "xMinYMin meet")

    const sankey = d3
      .sankey()
      .nodeWidth(14)
      .nodePadding(14)
      .extent([
        [margin.left, margin.top],
        [width - margin.right, height - margin.bottom],
      ])

    let laidOut
    try {
      laidOut = sankey(graph)
    } catch (e) {
      this.placeholder("Couldn't render the money-flow chart.")
      return
    }

    // Links
    svg
      .append("g")
      .attr("fill", "none")
      .selectAll("path")
      .data(laidOut.links)
      .join("path")
      .attr("d", d3.sankeyLinkHorizontal())
      .attr("stroke", (d) => colorFor(d.source))
      .attr("stroke-opacity", 0.4)
      .attr("stroke-width", (d) => Math.max(1, d.width))
      .append("title")
      .text((d) => `${d.source.label} → ${d.target.label}\n${this.fmt(d.value)}`)

    // Nodes
    const node = svg
      .append("g")
      .selectAll("g")
      .data(laidOut.nodes)
      .join("g")

    node
      .append("rect")
      .attr("x", (d) => d.x0)
      .attr("y", (d) => d.y0)
      .attr("height", (d) => Math.max(1, d.y1 - d.y0))
      .attr("width", (d) => d.x1 - d.x0)
      .attr("fill", (d) => colorFor(d))
      .attr("rx", 2)
      .append("title")
      .text((d) => `${d.label}\n${this.fmt(d.value)}`)

    // Labels: to the right of left-edge nodes, left of right-edge nodes.
    node
      .append("text")
      .attr("class", "sankey-node-label")
      .attr("x", (d) => (d.x0 < width / 2 ? d.x1 + 6 : d.x0 - 6))
      .attr("y", (d) => (d.y1 + d.y0) / 2)
      .attr("dy", "0.35em")
      .attr("text-anchor", (d) => (d.x0 < width / 2 ? "start" : "end"))
      .text((d) => d.label)
  }

  placeholder(message) {
    const div = document.createElement("div")
    div.className = "sankey-placeholder"
    div.textContent = message
    this.element.appendChild(div)
  }

  fmt(value) {
    try {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(value)
    } catch (e) {
      return `$${value}`
    }
  }
}
