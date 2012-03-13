((plunker) ->

  class plunker.Previewer extends Backbone.View
    preview: Handlebars.compile """
      <iframe frameborder="0" marginheight="0" marginwidth="0" width="100%" height="100%"></iframe>
    """
    
    compile: Handlebars.compile """
      <div class="title"></div>
      <div class="compiled"></div>
    """
    
    # Do nothing by default
    template: -> ""
    
    events:
      "click .lineno"     : (e) ->
        line = $(e.target).attr("data-line")
        char = $(e.target).attr("data-char")
        
        plunker.views.textarea.ace.gotoLine(line, char)
    
    initialize: ->
      self = @
      
      update = _.debounce((->
        self.updatePreview()
        self.updateCompile()
      ), 1000)
      
      plunker.mediator.on "intent:live-off",  -> self.enable()
      plunker.mediator.on "intent:live-preview", -> self.enable("preview")
      plunker.mediator.on "intent:live-compile", -> self.enable("compile")
      
      @model.plunk.on "change:index", update
      @model.buffers.on "reset change:content change:filename", update
  
      plunker.mediator.on "intent:refresh", @updatePreview
      plunker.mediator.on "event:activate", @updateCompile

      # Full-screen preview stuff
      plunker.mediator.on "intent:preview-enable", ->
        self.oldmode = self.mode
        
        $("#content").removeClass("editor").removeClass("sidebar")
        
        self.enable "preview"
        
        plunker.mediator.trigger "event:preview-enable"
      
      plunker.mediator.on "intent:preview-disable", ->
        $("#content").addClass("editor").addClass("sidebar")
        
        self.enable self.oldmode

        plunker.mediator.trigger "event:preview-disable"

    updatePreview: =>
      self = @
  
      if @mode == "preview"
        plunk = new plunker.Plunk _.defaults @model.toJSON(),
          expires: new Cromag(Cromag.now() + 30 * 1000).toISOString()
        
        plunk.on "sync", ->
          self.$("iframe").attr "src", plunk.get("raw_url")
          plunker.mediator.trigger "event:refresh", plunk
          
        plunk.save()
    
    updateCompile: (filename) =>
      self = @
      
      if @mode == "compile"
        filename ||= @model.last()
        if filename and (buffer = @model.buffers.get(filename)) and (code = buffer.get("content") or "")
          $title = @$(".title").text("").hide()
          $compiled = @$(".compiled")
  
          $title.text(buffer.mode.title or "")
          
          rerender = (body, mode = buffer.mode) ->
            highlighted = staticHighlight(body, mode.mode)
            $compiled.html(highlighted.html)
        
          if compiler = plunker.compilers[buffer.mode.name]
            compiler code, (err, res) ->
              if err then return rerender(err.toString())

              $title.text(res.title).show() if res.title
              
              switch res.type
                when "code"
                  plunker.modes.loadByName res.lang, (mode) ->
                    rerender(res.body, mode) if mode
                else
                  $compiled.html res.body
          else rerender(code, buffer.mode)
        
    enable: (@mode) =>
      self = @
  
      switch @mode
        when "preview"
          $("#content").addClass("live")
          
          @template = @preview
          @render()
          
          @updatePreview()
          
          plunker.mediator.trigger "event:live-preview"

        when "compile"
          $("#content").addClass("live")
          
          @template = @compile
          @render()
  
          @updateCompile()
          
          plunker.mediator.trigger "event:live-compile"
  
        else
          $("#content").removeClass("live")
          
          @template = -> ""
          @render()
          
          plunker.mediator.trigger "event:live-off"
      
      plunker.mediator.trigger "event:resize"
  
      
    render: (context = {}) =>
      @$el.html @template(context)
      @
      
)(@plunker ||= {})