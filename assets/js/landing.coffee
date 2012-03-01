jQuery.timeago.settings.strings.seconds = "seconds"

Handlebars.registerHelper "dateToLocaleString", (isoString) ->
  new Cromag(isoString).toLocaleString()

Handlebars.registerHelper "arrayJoinSpace", (array) ->
  array.join(" ")

$ ->

  window.plunks = new PlunkCollection()

  recent = new RecentPlunks
    collection: plunks
    el: document.getElementById("recent")

  plunks.fetch()

  importer = new Importer
    collection: plunks
    el: document.getElementById("importer")
