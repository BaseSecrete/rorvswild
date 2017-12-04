var RorVsWild = this.RorVsWild = {};

RorVsWild.Local = function(container) {
  this.root = container
  this.active = false
  this.data = JSON.parse((this.container = container).getAttribute("data-json"))
  this.requests = this.data.map(function(data) {
    return new RorVsWild.Local.Request(data)
  })
  this.render()
}

RorVsWild.Local.prototype.render = function() {
  Barber.render("RorVsWild.Local", this, this.root)
}

RorVsWild.Local.prototype.lastRuntime = function() {
  return this.requests[0].runtime()
}

RorVsWild.Local.prototype.toggle = function() {
  this.active ? this.collapse() : this.expand()
}

RorVsWild.Local.prototype.expand = function() {
  this.currentRequest = this.requests[0]
  this.active = true
  this.render()
}

RorVsWild.Local.prototype.collapse = function() {
  this.active = false
  this.render()
}

RorVsWild.Local.formatRuntime = function(runtime) {
  return runtime > 0 && runtime < 1 ? "<1" : Math.round(runtime)
}

RorVsWild.Local.formatImpact = function(impact) {
  return impact > 0 && impact < 1 ? "<1" : Math.round(impact)
}

RorVsWild.Local.formatDateTime = function(date) {
  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  var minutes = date.getMinutes() < 10 ? "0" + date.getMinutes() : date.getMinutes()
  var hours = date.getHours() < 10 ? "0" +  date.getHours() : date.getHours()
  return [date.getDate(), months[date.getMonth()], hours + ":" + minutes].join(" ")
}

RorVsWild.Local.prototype.goToRequestDetails = function(event) {
  var id = parseInt(event.currentTarget.getAttribute("data-request-id"))
  this.currentRequest = this.requests.find(function(req) { return req.id == id })
  console.log(this.currentRequest)
  this.render()
}

RorVsWild.Local.prototype.goToHistory = function(event) {
  this.currentRequest = null
  this.render()
}

RorVsWild.Local.prototype.containerStyle = function() {
  if (!this.active)
    return 'display: none;'
}

////////////////////////////////////////////////////////////////////////////////////////////////////



RorVsWild.Local.Request = function(data) {
  this.id = Math.round(Math.random() * 100000000)
  this.data = data
  this.name = data.name
  this.path = data.path
  this.startedAt = RorVsWild.Local.formatDateTime(new Date(data.started_at))
}

RorVsWild.Local.Request.prototype.runtime = function() {
  return RorVsWild.Local.formatRuntime(this.data.runtime)
}

RorVsWild.Local.Request.prototype.sections = function() {
  return this.data.sections.map(function(section) {
    var runtime = (section.total_runtime - section.children_runtime)
    return {
      impact: RorVsWild.Local.formatImpact(runtime * 100 / this.data.runtime),
      averageRuntime: RorVsWild.Local.formatRuntime(runtime / section.calls),
      command: section.command,
      calls: section.calls,
      kind: section.kind.substring(0, 7),
      file: section.file,
      line: section.line,
      runtime: runtime,
    }
  }.bind(this)).sort(function(a, b) { return b.runtime - a.runtime })
}
