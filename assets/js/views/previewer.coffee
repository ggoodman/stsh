class window.Previewer extends Backbone.View
  initialize: ->
    self = @

    update = _.debounce(@updatePlunk, 1000)
    
    @model.on "change:index", update
    @model.buffers.on "reset change:content change:filename", update

    plunker.on "intent:refresh", update
  
  updatePlunk: =>
    self = @

    json = @model.toJSON()
    json.expires = new Cromag(Cromag.now() + 30 * 1000).toISOString()

    plunk = new Plunk(json)
    plunk.on "sync", ->
      self.$("iframe").attr "src", plunk.get("raw_url")
      plunker.trigger "event:refresh", plunk
    plunk.save()
