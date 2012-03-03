class window.Previewer extends Backbone.View
  initialize: ->
    self = @
    
    @plunks = new PlunkCollection
    
    render = _.debounce(@render, 1000)
    
    @model.on "change", render
    @model.buffers.on "all", render
  
  render: =>
    $iframe = @$el.find("iframe")
    
    json = @model.toJSON()
    json.expires = new Cromag(30000 + Cromag.now()).toISOString()
    delete json.active
    
    plunk = @plunks.create(json)
    plunk.on "sync", ->
      $iframe.attr "src", plunk.get("raw_url")