var RorVsWild = this.RorVsWild = {};

RorVsWild.Local = function(container) {
  this.root = container
  this.active = false
  RorVsWild.Local.editorUrl = container.dataset.editorUrl
  if (this.embedded = location.pathname != "/rorvswild")
    window.addEventListener("keydown", this.keydown.bind(this))
  else
    this.active = true
  this.goToRequestIndex()
}

RorVsWild.Local.prototype.getRequests = function(callback) {
  this.getJson("/rorvswild/requests.json", function(data) {
    this.requests = data.map(function(attributes) { return new RorVsWild.Local.Request(attributes) })
    callback()
  }.bind(this))
}

RorVsWild.Local.prototype.getJobs = function(callback) {
  this.getJson("/rorvswild/jobs.json", function(data) {
    this.jobs = data.map(function(attributes) { return new RorVsWild.Local.Request(attributes) })
    callback()
  }.bind(this))
}

RorVsWild.Local.prototype.getErrors = function(callback) {
  this.getJson("/rorvswild/errors.json", function(data) {
    this.errors = data.map(function(attributes) { return new RorVsWild.Local.Error(attributes) })
    callback()
  }.bind(this))
}

RorVsWild.Local.prototype.getJson = function(path, callback) {
  var request = new XMLHttpRequest()
  request.open("GET", path, true)

  request.onload = function(event) {
    if (request.status >= 200 && request.status < 400) {
      callback(JSON.parse(request.response))
    } else {
      console.error("Unexpected response code " + request.status + " while fetching RorVswild data.")
    }
  }

  request.onerror = function() {
    console.error("Error while fetching RorVswild data.")
  }

  request.send()
}

RorVsWild.Local.prototype.render = function(view) {
  this.view = view
  Barber.render("RorVsWild.Local", this, this.root)
  Prism.highlightAllUnder(this.root)
}

RorVsWild.Local.prototype.renderBody = function() {
  var templates = Barber.partials()
  return Mustache.render(templates["RorVsWild.Local." + this.view], this, templates)
}

RorVsWild.Local.prototype.lastRuntime = function() {
  return this.requests[0] ? this.requests[0].runtime() : "N/A"
}

RorVsWild.Local.prototype.toggle = function(event) {
  this.active ? this.collapse() : this.expand(event)
}

RorVsWild.Local.prototype.toggleCommand = function(event) {
  document.querySelector(event.currentTarget.dataset.target).classList.toggle("is-open")
}

RorVsWild.Local.prototype.expand = function() {
  this.active = true
  this.goToRequestDetail(event)
}

RorVsWild.Local.prototype.collapse = function() {
  this.active = false
  this.goToRequestIndex()
}

RorVsWild.Local.prototype.keydown = function(event) {
  if (event.key == "Escape")
    this.collapse()
}

RorVsWild.Local.relevantRounding = function(value) {
  if (!value || value == 0)
    return 0
  else if (value < 0.01)
    return value
  else if (value < 1)
    return Number(value.toFixed(2))
  else if (value < 10)
    return Number(value.toFixed(1))
  else
    return Number(value.toFixed(0))
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

RorVsWild.Local.prototype.goToRequestDetail = function(event) {
  this.root.dataset.tab = "requests"
  var uuid = event.currentTarget.dataset.uuid
  this.currentRequest = this.requests.find(function(req) { return req.uuid == uuid })
  this.render("RequestDetail")
}

RorVsWild.Local.prototype.goToRequestIndex = function(event) {
  this.root.dataset.tab = "requests"
  this.getRequests(function() { this.render("RequestIndex") }.bind(this))
}

RorVsWild.Local.prototype.goToJobIndex = function(event) {
  this.root.dataset.tab = "jobs"
  this.getJobs(function() { this.render("JobIndex") }.bind(this))
}

RorVsWild.Local.prototype.goToJobDetail = function(event) {
  var uuid = event.currentTarget.dataset.uuid
  this.currentJob = this.jobs.find(function(job) { return job.uuid == uuid })
  this.render("JobDetail")
}

RorVsWild.Local.prototype.goToErrors = function(event) {
  this.root.dataset.tab = "errors"
  this.getErrors(function() { this.render("ErrorIndex") }.bind(this))
}

RorVsWild.Local.prototype.goToErrorDetail = function(event) {
  var uuid = event.currentTarget.dataset.uuid
  this.currentError = this.errors.find(function(err) { return err.uuid == uuid })
  this.render("ErrorDetail")
}

RorVsWild.Local.prototype.containerClass = function() {
  if (!this.active)
    return "is-hidden"
}

RorVsWild.Local.kindToLanguage = function(kind) {
  switch (kind) {
    case "sql": return "language-sql"
    case "mongo": return "language-javascript"
    case "elasticsearch": return "language-json"
    default: return "language-none"
  }
}

RorVsWild.Local.pathToUrl = function(cwd, file, line) {
  if (RorVsWild.Local.editorUrl) {
    var path = file[0] == "/" ? file : cwd + "/" + file
    return RorVsWild.Local.editorUrl.replace("${path}", path).replace("${line}", line)
  }
}

RorVsWild.Local.lastId = 0

RorVsWild.Local.nextId = function() {
  return RorVsWild.Local.lastId += 1
}

RorVsWild.Local.Request = function(data) {
  this.data = data
  this.uuid = data.uuid
  this.name = data.name
  this.path = data.path
  this.queuedAt = RorVsWild.Local.formatDateTime(new Date(data.queued_at))
}

RorVsWild.Local.Request.prototype.runtime = function() {
  return RorVsWild.Local.relevantRounding(this.data.runtime)
}

RorVsWild.Local.Request.prototype.sections = function() {
  return this.data.sections.map(function(section) {
    var runtime = (section.total_runtime - section.children_runtime)
    return {
      id: RorVsWild.Local.nextId(),
      impact: RorVsWild.Local.formatImpact(runtime * 100 / this.data.runtime),
      language: RorVsWild.Local.kindToLanguage(section.kind),
      totalRuntime: RorVsWild.Local.relevantRounding(section.total_runtime),
      asyncRuntime: RorVsWild.Local.relevantRounding(section.async_runtime),
      childrenRuntime: RorVsWild.Local.relevantRounding(section.children_runtime),
      selfRuntime: RorVsWild.Local.relevantRounding(runtime),
      runtime: RorVsWild.Local.relevantRounding(runtime),
      averageRuntime: RorVsWild.Local.relevantRounding(runtime / section.calls),
      command: section.kind != "view" ? section.command : null,
      calls: section.calls,
      kind: section.kind.substring(0, 7),
      file: section.file,
      line: section.line,
      location: section.kind == "view" ? section.file : section.file + ":" + section.line,
      locationUrl: RorVsWild.Local.pathToUrl(this.data.environment.cwd, section.file, section.line),
      isAsync: RorVsWild.Local.relevantRounding(section.async_runtime) > 0,
    }
  }.bind(this)).sort(function(a, b) { return b.selfRuntime - a.selfRuntime })
}

RorVsWild.Local.Request.prototype.sectionsImpactPerKind = function() {
  var total = 0
  var perKind = this.sections().reduce(function(object, section) {
    object[section.kind] = (object[section.kind] || 0) + section.runtime
    total += section.runtime
    return object
  }, {})
  return Object.entries(perKind).sort(function(a, b) { return b[1] - a[1] })
    .map(function(item) { return {kind: item[0], impact: Math.round((item[1] / total * 100) * 10) / 10} })
}

RorVsWild.Local.Error = function(data) {
  this.data = data
  this.backtrace = data.backtrace
  this.context = data.context
  this.environment = data.environment
  this.exception = data.exception
  this.message = data.message
  this.file = data.file
  this.line = data.line
  this.locationUrl = RorVsWild.Local.pathToUrl(data.environment.cwd, data.file, data.line)
  this.message = data.message
  this.queuedAt = RorVsWild.Local.formatDateTime(new Date(data.queued_at))
  this.uuid = data.uuid
  this.parameters = data.parameters
  this.request = data.request
  this.job = data.job
}

RorVsWild.Local.Error.prototype.shortMessage = function() {
  return this.message.length < 160 ? this.message : this.message.substring(0, 160) + "…"
}

RorVsWild.Local.Error.prototype.hasRequest = function() {
  return this.request != null
}

RorVsWild.Local.Error.prototype.eachRequestProperty = function() {
  return this.request && this.objectToProperties(this.request)
}

RorVsWild.Local.Error.prototype.hasParameters = function() {
  return this.parameters != null
}

RorVsWild.Local.Error.prototype.parametersInJson = function() {
  return JSON.stringify(this.parameters, null, 2)
}

RorVsWild.Local.Error.prototype.hasRequestHeaders = function() {
  return this.request && this.request.headers != null
}

RorVsWild.Local.Error.prototype.eachRequestHeader = function() {
  return this.request && this.request.headers && this.objectToProperties(this.request.headers)
}

RorVsWild.Local.Error.prototype.eachEnvironment = function() {
  return this.objectToProperties(this.environment)
}

RorVsWild.Local.Error.prototype.hasContext = function() {
  return this.context != null
}

RorVsWild.Local.Error.prototype.eachContext = function() {
  return this.objectToProperties(this.context)
}

RorVsWild.Local.Error.prototype.objectToProperties = function(object) {
  var array = []
  for (var name in object)
    if (object.hasOwnProperty(name))
      array.push({name: name, value: object[name]})
  return array
}

RorVsWild.Local.Error.prototype.compactBacktrace = function() {
  var cwd = this.environment.cwd
  cwd.endsWith("/") || (cwd += "/")
  var vendorPath = (cwd + "vendor/bundle")
  return this.backtrace.filter(function(path) {
    return path.startsWith(cwd) && !path.startsWith(vendorPath)
  }).map(function(path) { return path.replace(cwd, "") }).join("\n")
}

RorVsWild.Local.Error.prototype.compactBacktraceLocations = function() {
  var cwd = this.environment.cwd
  return this.compactBacktrace().split("\n").map(function(path) {
    var fileAndLine = path.split(":")
    return {path: path, url: RorVsWild.Local.pathToUrl(cwd, fileAndLine[0], fileAndLine[1])}
  })
}

RorVsWild.Local.Error.prototype.formattedBacktrace = function() {
  return this.backtrace.join("\n")
}
