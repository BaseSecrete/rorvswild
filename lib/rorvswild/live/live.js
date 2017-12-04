var RorVsWild = this.RorVsWild = {};

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
  return this.requests[0].runtime()
}

RorVsWild.Live.prototype.toggle = function() {
  this.active ? this.collapse() : this.expand()
}

RorVsWild.Live.prototype.expand = function() {
  this.currentRequest = this.requests[0]
  this.active = true
  this.render()
}

RorVsWild.Live.prototype.collapse = function() {
  this.active = false
  this.render()
}

RorVsWild.Live.formatRuntime = function(runtime) {
  return runtime > 0 && runtime < 1 ? "<1" : Math.round(runtime)
}

RorVsWild.Live.formatImpact = function(impact) {
  return impact > 0 && impact < 1 ? "<1" : Math.round(impact)
}

RorVsWild.Live.formatDateTime = function(date) {
  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  var minutes = date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes()
  var hours = date.getHours() < 10 ? "0" +  date.getHours() : date.getHours()
  return [date.getDate(), months[date.getMonth()], hours + ":" + minutes].join(" ")
}

RorVsWild.Live.prototype.goToRequestDetails = function(event) {
  var id = parseInt(event.currentTarget.getAttribute("data-request-id"))
  this.currentRequest = this.requests.find(function(req) { return req.id == id })
  console.log(this.currentRequest)
  this.render()
}

RorVsWild.Live.prototype.goToHistory = function(event) {
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
  this.startedAt = RorVsWild.Live.formatDateTime(new Date(data.started_at))
}

RorVsWild.Live.Request.prototype.runtime = function() {
  return RorVsWild.Live.formatRuntime(this.data.runtime)
}

RorVsWild.Live.Request.prototype.sections = function() {
  return this.data.sections.map(function(section) {
    var runtime = (section.total_runtime - section.children_runtime)
    return {
      impact: RorVsWild.Live.formatImpact(runtime * 100 / this.data.runtime),
      averageRuntime: RorVsWild.Live.formatRuntime(runtime / section.calls),
      command: section.command,
      calls: section.calls,
      kind: section.kind.substring(0, 7),
      file: section.file,
      line: section.line,
      runtime: runtime,
    }
  }.bind(this)).sort(function(a, b) { return b.runtime - a.runtime })
}
