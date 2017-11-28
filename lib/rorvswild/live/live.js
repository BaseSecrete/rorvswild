RorVsWild = {}

RorVsWild.Live = function(container) {
  this.root = container
  this.active = false
  this.data = JSON.parse((this.container = container).getAttribute("data-json"))
  this.requests = this.data.map(function(data) {
    return new RorVsWild.Live.Request(data)
  })
  this.render()
}

RorVsWild.Live.prototype.render = function() {
  Barber.render("RorVsWild.Live", this, this.root)
}

RorVsWild.Live.prototype.lastRuntime = function() {
  return this.requests[this.requests.length-1].runtime()
}

RorVsWild.Live.prototype.expand = function() {
  this.active = true
  this.render()
}

RorVsWild.Live.prototype.collapse = function() {
  this.active = false
  this.render()
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

RorVsWild.Live.prototype.showRequest = function(event) {
  var id = parseInt(event.currentTarget.getAttribute("data-request-id"))
  this.currentRequest = this.requests.find(function(req) { return req.id == id })
  console.log(this.currentRequest)
  this.render()
}

RorVsWild.Live.prototype.goBackToSummary = function(event) {
  this.currentRequest = null
  this.render()
}

RorVsWild.Live.prototype.containerStyle = function() {
  if (!this.active)
    return 'display: none;'
}

////////////////////////////////////////////////////////////////////////////////////////////////////



RorVsWild.Live.Request = function(data) {
  this.id = Math.round(Math.random() * 100000000)
  this.data = data
  this.name = data.name
  this.path = data.path
  this.started_at = data.started_at
  if (data.sections)
    this.sections = data.sections.map(function(section) { return new RorVsWild.Live.Section(section) })
  else
    this.sections = []
}

RorVsWild.Live.Request.prototype.runtime = function() {
  return RorVsWild.Live.formatRuntime(this.data.runtime)
}

RorVsWild.Live.Section = function(data) {
  this.data = data
  this.file = data.file
  this.line = data.line
  this.calls = data.calls
  this.averageRuntime = data.averageRuntime
}
