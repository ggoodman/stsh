#= require importers/github
#= require models/plunks
#= require views/cards
#= require views/importer

((plunker) ->
  jQuery.timeago.settings.strings.seconds = "seconds"
  
  Handlebars.registerHelper "dateToLocaleString", (isoString) ->
    new Cromag(isoString).toLocaleString()
  
  Handlebars.registerHelper "arrayJoinSpace", (array) ->
    array.join(" ")
  
  $ ->
  
    window.plunks = new plunker.PlunkCollection()
  
    recent = new plunker.RecentPlunks
      collection: plunks
      el: document.getElementById("recent")
  
    plunks.fetch()
  
    importer = new plunker.Importer
      collection: plunks
      el: document.getElementById("importer")
)(@plunker ||= {})