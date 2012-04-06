((plunker) ->
  
  class Filename extends Backbone.View
    tagName: "li"
    className: "file"

    template: Handlebars.compile """
      {{filename}}
      <span class="marker">*</span>
    """


    events:
      "click":    -> plunker.mediator.trigger "intent:activate", @model.get("filename")
      "dblclick": -> plunker.mediator.trigger "intent:fileRename", @model.get("filename")
    
    initialize: ->
      self = @
      
      plunker.mediator.on "event:activate", @onEventActivate
      
      @model.on "remove", ->
        plunker.mediator.off "event:activate", self.onEventActivate
        self.model.off "change:filename", self.render
        self.model.off "change:content", self.onChangeContent
      
      @model.on "change:filename", @render
      @model.on "change:content", @onChangeContent

    onEventActivate: (filename) =>
      @active = filename
      
      if @model.get("filename") == filename
        @$el.addClass("active")
        @$el.removeClass("changed")
      else
        @$el.removeClass("active")
        
    onChangeContent: (buffer, content, options) =>
      @$el.addClass("changed") unless @active == buffer.id
    
    render: =>
      @$el.html @template
        filename: @model.get("filename")
      @
    

  class plunker.Sidebar extends Backbone.View
    events:
      "click .add":         (e) -> plunker.mediator.trigger "intent:fileAdd"
      "click .remove":      (e) -> plunker.mediator.trigger "intent:fileRemove", @model.last()
      
      "click .wordwrap":    (e) ->
        if buffer = @model.getActiveBuffer()
          buffer.session.setUseWrapMode($(e.target).prop("checked"))
          buffer.session.setWrapLimitRange(80, 80)
      
      "change .theme":      (e) ->
        plunker.themes.load $(e.target).attr("value"), (theme) ->
          plunker.views.textarea.ace.setTheme(theme)
      
      "keyup .description": (e) -> @model.set("description", @$(e.target).val(), handled: true)

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
        
        plunker.mediator.trigger "intent:activate", self.model.last()
      
      @model.buffers.on "reset", (coll) ->
        _.each self.views, (view) -> removeBuffer(view.model)
        coll.each addBuffer
        
        plunker.mediator.trigger "intent:activate", self.model.guessIndex()
      
      @model.buffers.on "add", addBuffer
      @model.buffers.on "remove", removeBuffer
      
      @model.on "change:description", (model, value, options) ->
        unless options.handled is true
          self.$(".description").val(self.model.get("description"))
      
      plunker.mediator.on "event:activate", (filename) ->
        buffer = self.model.getActiveBuffer()
        self.$(".wordwrap").prop("checked", buffer.session.getUseWrapMode())

      
    render: =>
      
      @
      
    
)(@plunker ||= {})