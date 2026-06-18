var RorVsWild = this.RorVsWild = {};

RorVsWild.Local = function(container) {
  this.root = container
  this.active = false
  this.lowImpactExpanded = false
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

RorVsWild.Local.prototype.resetLowImpactSections = function() {
  var button = document.querySelector("[data-rorvswild-local-toggle-low-impact]")
  document.querySelectorAll("[data-rorvswild-local-low-impact]").forEach(function(section) {
    section.classList.add("is-hidden")
  })
  if (button) button.textContent = "↓ View low impact sections"
  this.lowImpactExpanded = false
}

RorVsWild.Local.prototype.toggleLowImpactSections = function(event) {
  var sections = document.querySelectorAll("[data-rorvswild-local-low-impact]")
  var isHidden = sections[0].classList.contains("is-hidden")

  if (isHidden) {
    sections.forEach(function(section) { section.classList.remove("is-hidden") })
    event.currentTarget.textContent = "↑ Hide low impact sections"
    this.lowImpactExpanded = true
  } else {
    this.resetLowImpactSections()
  }
}

RorVsWild.Local.prototype.getActiveKindFilter = function() {
  var active = document.querySelector("[data-rorvswild-local-breakdown-item].is-active")
  return active ? active.dataset.kind : null
}

RorVsWild.Local.prototype.getSectionQueryFilter = function() {
  var input = document.querySelector("[data-rorvswild-local-section-filter]")
  var query = input && input.value.trim()
  return query && query.length > 0 ? query : null
}

RorVsWild.Local.highlightMatches = function(text, query) {
  if (!query) return Mustache.escape(text)

  var lowerText = text.toLowerCase()
  var lowerQuery = query.toLowerCase()
  var result = ""
  var start = 0
  var index

  while ((index = lowerText.indexOf(lowerQuery, start)) !== -1) {
    result += Mustache.escape(text.slice(start, index))
    result += '<mark class="rorvswild-local-panel__section-filter-highlight">'
    result += Mustache.escape(text.slice(index, index + query.length))
    result += "</mark>"
    start = index + query.length
  }

  result += Mustache.escape(text.slice(start))
  return result
}

RorVsWild.Local.prototype.restoreOriginalContent = function(element) {
  if (element.dataset.rorvswildLocalSectionOriginalContent) {
    element.innerHTML = element.dataset.rorvswildLocalSectionOriginalContent
    delete element.dataset.rorvswildLocalSectionOriginalContent
  }
}

RorVsWild.Local.prototype.clearHighlightFilterText = function() {
  document.querySelectorAll("[data-rorvswild-local-filter-text]").forEach(this.restoreOriginalContent)
}

RorVsWild.Local.prototype.highlightFilterText = function(query) {
  document.querySelectorAll("[data-rorvswild-local-section]").forEach(function(section) {
    var element = section.querySelector("[data-rorvswild-local-filter-text]")
    if (!element) return

    if (section.classList.contains("is-hidden"))
      return this.restoreOriginalContent(element)

    if (element.dataset.rorvswildLocalSectionOriginalContent === undefined)
      element.dataset.rorvswildLocalSectionOriginalContent = element.innerHTML

    element.innerHTML = RorVsWild.Local.highlightMatches(element.textContent, query)
  }.bind(this))
}

RorVsWild.Local.prototype.filterSections = function() {
  var kind = this.getActiveKindFilter()
  var query = this.getSectionQueryFilter()
  var lowerQuery = query && query.toLowerCase()
  var toggleButton = document.querySelector("[data-rorvswild-local-toggle-low-impact]")

  document.querySelectorAll("[data-rorvswild-local-section]").forEach(function(section) {
    var filterElement = section.querySelector("[data-rorvswild-local-filter-text]")
    var text = filterElement ? filterElement.textContent.trim().toLowerCase() : ""
    var matchesKind = !kind || section.dataset.kind === kind
    var matchesText = !query || text.indexOf(lowerQuery) !== -1
    matchesKind && matchesText ? section.classList.remove("is-hidden") : section.classList.add("is-hidden")
  })

  if (query) {
    this.highlightFilterText(query)
  } else {
    this.clearHighlightFilterText()
    if (!kind && !this.lowImpactExpanded) this.resetLowImpactSections()
  }

  if (toggleButton) toggleButton.style.display = query || kind ? "none" : ""
}

RorVsWild.Local.prototype.filterSectionsByKind = function(event) {
  var li = event.currentTarget
  var isActive = li.classList.contains("is-active")

  document.querySelectorAll("[data-rorvswild-local-breakdown-item]").forEach(function(el) {
    el.classList.remove("is-active")
  })

  if (!isActive) li.classList.add("is-active")
  this.filterSections()
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
  if (!date || isNaN(date.getTime())) return ""
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
    var impactValue = runtime * 100 / this.data.runtime
    return {
      id: RorVsWild.Local.nextId(),
      impact: RorVsWild.Local.formatImpact(impactValue),
      isLowImpact: impactValue < 1,
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
      isLineRelevant: section.line > 0,
      location: section.file + (section.line > 0 ? ":" + section.line : ""),
      locationUrl: RorVsWild.Local.pathToUrl(this.data.environment.cwd, section.file, section.line),
      isAsync: RorVsWild.Local.relevantRounding(section.async_runtime) > 0,
    }
  }.bind(this)).sort(function(a, b) { return b.selfRuntime - a.selfRuntime })
}

RorVsWild.Local.Request.prototype.hasLowImpactSections = function() {
  return this.sections().some(function(section) { return section.isLowImpact })
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
