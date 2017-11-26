RorVsWild = {}

RorVsWild.Live = function(container) {
  this.request = JSON.parse((this.container = container).getAttribute("data-json"))
  console.log(this.request)
}

RorVsWild.Live.prototype.runtime = function() {
  return RorVsWild.Live.formatRuntime(this.request.runtime)
}

RorVsWild.Live.prototype.expand = function() {
  this.container.querySelector("#rorvswild-live-request").style.display = "block"
}

RorVsWild.Live.prototype.collapse = function() {
  this.container.querySelector("#rorvswild-live-request").style.display = "none"
}

RorVsWild.Live.prototype.sections = function() {
  return this.request.sections.map(function(section) {
    var runtime = (section.total_runtime - section.children_runtime)
    return {
      impact: RorVsWild.Live.formatImpact(runtime * 100 / this.request.runtime),
      averageRuntime: RorVsWild.Live.formatRuntime(runtime / section.calls),
      command: section.command,
      calls: section.calls,
      kind: section.kind,
      file: section.file,
      line: section.line,
      runtime: runtime,
    }
  }.bind(this)).sort(function(a, b) { return b.runtime - a.runtime })
}

RorVsWild.Live.formatRuntime = function(runtime) {
  return runtime > 0 && runtime < 1 ? "< 1 ms" : Math.round(runtime) + " ms"
}

RorVsWild.Live.formatImpact = function(impact) {
  return impact > 0 && impact < 1 ? "< 1 %" : Math.round(impact) + " %"
}
