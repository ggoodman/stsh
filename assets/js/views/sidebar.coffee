((exports) ->
  
  class Filename extends Backbone.View
    tagName: "li"
    className: "file"
    
    events:
      "click":    "onClick"
    
    initialize: ->
      self = @
      
      plunker.on "activate", (filename) ->
        if self.model.get("filename") == filename
          self.$el.addClass("active")
        else
          self.$el.removeClass("active")
    
    render: =>
      @$el.text(@model.get("filename"))
      @
    
    onClick: -> plunker.trigger "activate", @model.get("filename")

  class exports.Sidebar extends Backbone.View
    initialize: ->
      self = @
      @views = {}
      $files = @$(".files")
      
      addBuffer = (buffer) ->
        view = new Filename(model: buffer)
        self.views[buffer.id] = view
        $files.append view.render().$el
      
      removeBuffer = (buffer) ->
        self.views[buffer.id].remove()
        delete self.views[buffer.id]
      
      @model.buffers.on "reset", (coll) ->
        _.each self.views, removeBuffer
        self.model.buffers.each addBuffer
      
      @model.buffers.on "add", addBuffer
      
    render: =>
      @
    
)(window)