((plunker) ->
  
  class Filename extends Backbone.View
    tagName: "li"
    className: "file"
    
    events:
      "click": -> plunker.mediator.trigger "intent:activate", @model.get("filename")
    
    initialize: ->
      self = @
      
      plunker.mediator.on "event:activate", @onEventActivate
      
      @model.on "change:filename", @render

    onEventActivate: (filename) =>
      if @model.get("filename") == filename
        @$el.addClass("active")
      else
        @$el.removeClass("active")
    
    render: =>
      @$el.text(@model.get("filename"))
      @
    

  class plunker.Sidebar extends Backbone.View
    events:
      "click .add":     -> plunker.mediator.trigger "intent:fileAdd"
      "click .remove":  -> plunker.mediator.trigger "intent:fileRemove"
      
      "change .description": (e) -> @model.plunk.set("description", @$(e.target).val(), silent: true)

    initialize: ->
      self = @
      @views = {}
      $files = @$(".files")

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
      
      @model.plunk.on "change:description", @render
      
    render: =>
      @$(".description").val(@model.plunk.get("description"))
      @
      
    
)(@plunker ||= {})