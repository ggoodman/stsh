class window.Previewer extends Backbone.View
  id: "preview"
  initialize: ->
    self = @
    
    @plunks = new PlunkCollection
    
    render = _.throttle(@render, 1000)
    
    @model.on "change", render
  
  render: =>
    $iframe = @$("iframe")
    
    json = @model.toJSON()
    delete json.active
    
    plunk = @plunks.create(json)
    plunk.on "sync", ->
      $iframe.attr "src", plunk.get("raw_url")