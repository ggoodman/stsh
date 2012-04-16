#= require lib/importer
#= require models/plunks

$ ->
  if matches = document.location.pathname.match /^\/([a-zA-Z0-9]{6})\//
    plunk = new plunker.Plunk(id: matches[1])

    plunk.on "change:token", -> $("#operations").addClass("owned") if plunk.get("token")
    plunk.on "change:source", -> $("#operations").addClass("source") if plunk.get("source")?.url
    plunk.on "sync", -> $("#plunk").attr "src", plunk.get("raw_url")

    plunk.fetch()

    $("button.refresh").click (e) ->
      unless plunk.get("source")?.url then alert "Unable to refresh a plunk without a source"
      else if confirm "Are you sure that you would like to refresh this plunk from its source?"
        plunker.import plunk.get("source").url,
          success: (json) ->
            plunk.set(json)
            plunk.save()
          error: (title, message) -> alert "#{title}: #{message}"

    $("button.delete").click (e) ->
      unless plunk.get("token") then alert "Unable to delete a plunk that you did not create"
      else if confirm "Are you sure that you would like to delete this plunk?"
        plunk.destroy
          wait: true
          success: -> document.location = document.location.origin
          error: -> alert "Failed to delete the plunk. Please try again."
