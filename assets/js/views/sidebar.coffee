((exports) ->
  
  class Filename extends Backbone.View
    tagName: "li"
    className: "file"
    
    events:
      "click":    "onClick"
    
    initialize: ->
      self = @
      
      plunker.on "event:activate", (filename) ->
        if self.model.get("filename") == filename
          self.$el.addClass("active")
        else
          self.$el.removeClass("active")
    
    render: =>
      @$el.text(@model.get("filename"))
      @
    
    onClick: -> plunker.trigger "intent:activate", @model.get("filename")

  class exports.Sidebar extends Backbone.View
    events:
      "click .add":     -> plunker.trigger "intent:fileAdd"
      "click .remove":  -> plunker.trigger "intent:fileRemove"

    initialize: ->
      self = @
      @views = {}
      $files = @$(".files")

      plunker.on "action:activate", (filename) -> self.active = filename

      addBuffer = (buffer) ->
        view = new Filename(model: buffer)
        self.views[buffer.cid] = view
        $files.append view.render().$el
      
      removeBuffer = (buffer) ->
        self.views[buffer.cid].remove()
        delete self.views[buffer.cid]
      
      @model.buffers.on "reset", (coll) ->
        _.each self.views, (view) -> removeBuffer(view.model)
        coll.each addBuffer
      
      @model.buffers.on "add", addBuffer
      @model.buffers.on "remove", removeBuffer
      
    render: =>
      @
      
    
)(window)