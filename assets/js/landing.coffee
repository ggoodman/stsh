#= require importers/github
#= require models/plunks
#= require views/cards
#= require views/importer

((plunker) ->
  jQuery.timeago.settings.strings.seconds = "seconds"

  Handlebars.registerHelper "or", (arg1, arg2) -> arg1 or arg2

  Handlebars.registerHelper "dateToLocaleString", (updated_at, created_at) ->
    new Cromag(updated_at or created_at).toLocaleString()
    
  Handlebars.registerHelper "dateToTimestamp", (updated_at, created_at) ->
    new Cromag(updated_at or created_at).valueOf()
  
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