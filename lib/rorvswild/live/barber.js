Barber = {}

Barber.launch = function(root) {
  var elements = (root || document).querySelectorAll("[data-barber]")
  Array.prototype.forEach.call(elements, Barber.start)
}

Barber.start = function(element) {
  var name = element.getAttribute("data-barber")
  var func = Barber.stringToFunction(name)
  if (func instanceof Function) {
    var view = Barber.instanciate(func, element)
    view && Barber.render(view)
  }
  else
    console.warn("View " + name + " is not a function.")
}

Barber.instanciate = function(func, element) {
  try {
    var view = new func(element)
    view.barber = {root: element, template: element.innerHTML}
    return view
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

Barber.render = function(view) {
  var html = Mustache.render(view.barber.template, view)
  view.barber.root.innerHTML = html
  Barber.listenActions(view.barber.root, view)
  Barber.listenEvents(view.barber.root, view)
}

Barber.listenActions = function(root, view) {
  root.querySelectorAll("[data-action]").forEach(function(element) {
    Barber.listenEvent(view, element, "click", element.getAttribute("data-action"))
  })
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
