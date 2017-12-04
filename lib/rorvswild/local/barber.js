var Mustache = this.Mustache
var Barber = this.Barber = {}

Barber.launch = function(root, namespace) {
  var elements = (root || document).querySelectorAll("[data-barber]")
  Array.prototype.forEach.call(elements, function(element) { Barber.start(element, namespace) })
}

Barber.start = function(element, namespace) {
  var name = element.getAttribute("data-barber")
  var func = Barber.stringToFunction(name, namespace)
  if (func instanceof Function)
    Barber.instanciate(func, element)
  else
    console.warn("View " + name + " is not a function.")
}

Barber.instanciate = function(func, element) {
  try {
    view = new func(element)
  } catch (ex) {
    console.error(ex)
  }
}

Barber.stringToFunction = function(fullName, parent) {
  var func = parent || window
  fullName.split(".").forEach(function(name) {
    if (!(func = func[name]))
      return null
  })
  return func
}

Barber.render = function(name, view, element) {
  var partials = Barber.partials()
  if (!partials[name]) {
    console.error("Partial " + name + " does not exists.")
    return
  }
  element.innerHTML = Mustache.render(partials[name], view, partials)
  Barber.listenEvents(element, view)
}

Barber.partials = function() {
  var elements = document.querySelectorAll('[type="x-tmpl-mustache"][data-partial]')
  return Array.prototype.reduce.call(elements, function(hash, element) {
    hash[element.getAttribute("data-partial")] = element.innerHTML
    return hash
  }, {})
}

Barber.listenEvents = function(root, view) {
  root.querySelectorAll("[data-events]").forEach(function(element) {
    element.getAttribute("data-events").split(" ").forEach(function(eventAndAction) {
      var array = eventAndAction.split("->")
      Barber.listenEvent(view, element, array[0], array[1])
    })
  })
}

Barber.listenEvent = function(view, element, event, action) {
  if (view[action] instanceof Function)
    element.addEventListener(event, view[action].bind(view))
  else
    console.warn("Action " + view.constructor.name + "." + action + " is not a function.")
}
