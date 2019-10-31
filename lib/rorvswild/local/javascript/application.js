(function() {
  var RorVsWild = {};
  var startRorVsWild = function() {
    // include javascript here
    Barber.launch(document.getElementById("RorVsWild.Local"), this)
  }.bind(RorVsWild)

  if (document.readyState != "loading")
    startRorVsWild()
  else
    document.addEventListener("DOMContentLoaded", startRorVsWild)
})()