var RorVsWild = this.RorVsWild = {};

RorVsWild.Local = function(container) {
  this.root = container
  this.embedded = !(this.active = location.pathname == "/rorvswild")
  this.fetchData()
}

RorVsWild.Local.prototype.fetchData = function() {
  var request = new XMLHttpRequest()
  request.open("GET", "/rorvswild.json", true)

  request.onload = function(event) {
    if (request.status >= 200 && request.status < 400) {
      this.data = JSON.parse(request.response)
      this.requests = this.data.map(function(data) { return new RorVsWild.Local.Request(data) })
      this.render()
    } else {
      console.error("Unexpected response code " + request.status + " while fetching RorVswild data.")
    }
  }.bind(this)

  request.onerror = function() {
    console.error("Error while fetching RorVswild data.")
  }

  request.send()
}

RorVsWild.Local.prototype.render = function() {
  Barber.render("RorVsWild.Local", this, this.root)
  Prism.highlightAllUnder(this.root)
}

RorVsWild.Local.prototype.lastRuntime = function() {
  return this.requests[0] ? this.requests[0].runtime() : "N/A"
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
  this.render()
}

RorVsWild.Local.prototype.goToHistory = function(event) {
  this.currentRequest = null
  this.render()
}

RorVsWild.Local.prototype.containerStyle = function() {
  if (!this.active)
    return 'display: none !important;'
}

RorVsWild.Local.kindToLanguage = function(kind) {
  switch (kind) {
    case "sql": return "language-sql"
    case "mongo": return "language-javascript"
    case "elasticsearch": return "language-json"
    default: return "language-none"
  }
}

RorVsWild.Local.lastId = 0

RorVsWild.Local.nextId = function() {
  return RorVsWild.Local.lastId += 1
}

RorVsWild.Local.Request = function(data) {
  this.id = RorVsWild.Local.nextId()
  this.data = data
  this.name = data.name
  this.path = data.path
  this.queuedAt = RorVsWild.Local.formatDateTime(new Date(data.queued_at))
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
      command: section.kind != "view" ? section.command : null,
      calls: section.calls,
      kind: section.kind.substring(0, 7),
      file: section.file,
      line: section.line,
      runtime: runtime,
      language: RorVsWild.Local.kindToLanguage(section.kind),
    }
  }.bind(this)).sort(function(a, b) { return b.runtime - a.runtime })
}
