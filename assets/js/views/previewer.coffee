(plunker || window.plunker = {}).compilers =
  coffee: (code, cb) ->
    $script "/js/compilers/coffee-script.js", "compiler-coffee"
    $script.ready "compiler-coffee", ->
      try
        compiled = CoffeeScript.compile(code, bare: true)
        return cb null,
          type: "code"
          body: compiled
          lang: "javascript"
      catch error
        return cb error
    return
  markdown: (code, cb) ->
    $script "/js/compilers/showdown.js", "compiler-showdown"
    $script.ready "compiler-showdown", ->
      converter = new Showdown.converter()
      try
        compiled = converter.makeHtml(code)
        return cb null,
          type: "html"
          body: compiled
      catch error
        return cb error
      return      


class window.LivePreview extends Backbone.View
  preview: Handlebars.compile """
    <iframe frameborder="0" marginheight="0" marginwidth="0" width="100%" height="100%"></iframe>
  """
  
  compile: Handlebars.compile """
    <div class="format"></div>
    <div class="compiled"></div>
  """
  
  # Do nothing
  template: -> ""
  
  initialize: ->
    self = @
    
    cbPreview = _.debounce(@updatePreview, 1000)
    cbCompile = _.debounce(@updateCompile, 1000)
    
    update = ->
      cbPreview()
      cbCompile()
    
    plunker.on "intent:live-off", -> self.enable()
    plunker.on "intent:live-preview", -> self.enable("preview")
    plunker.on "intent:live-compile", -> self.enable("compile")
    
    @model.on "change:index", update
    @model.buffers.on "reset change:content change:filename", update
    
    plunker.on "intent:preview-enable", ->
      self.oldmode = self.mode
      
      $("#content").removeClass("editor").removeClass("sidebar")
      
      self.enable "preview"
    
    plunker.on "intent:preview-disable", ->
      $("#content").addClass("editor").addClass("sidebar")
      
      self.enable self.oldmode

    plunker.on "intent:refresh", update
    plunker.on "event:activate", @updateCompile
  
  updatePreview: =>
    self = @

    if @mode == "preview"
      json = @model.toJSON()
      json.expires = new Cromag(Cromag.now() + 30 * 1000).toISOString()
  
      plunk = new Plunk(json)
      plunk.on "sync", ->
        self.$("iframe").attr "src", plunk.get("raw_url")
        plunker.trigger "event:refresh", plunk
      plunk.save()
  
  updateCompile: =>
    self = @
    
    $title = @$(".title").text("")
    $compiled = @$(".compiled")

    if @mode == "compile"
      if (filename = @model.getActive()) and (buffer = @model.buffers.get(filename)) and (code = buffer.get("content") or "")
      
        $title.text(buffer.mode.title or "")
        
        rerender = (body, mode) ->
          $title.text(mode.title)
          
          highlighted = staticHighlight(body, mode)
          $compiled.html(highlighted.html)
      
        if compiler = plunker.compilers[buffer.mode.name]
          compiler code, (err, res) ->
            if err
              return rerender(err.toString())
            switch res.type
              when "code"
                buffer.loadMode buffer.getMode(res.lang), (mode) ->
                  rerender(res.body, mode)
              else
                $compiled.html res.body
        else rerender(code, buffer.mode.mode)
      
  enable: (@mode) =>
    self = @

    switch @mode
      when "preview"
        $("#content").addClass("live")
        
        @template = @preview
        @render()
        
        @updatePreview()

      when "compile"
        $("#content").addClass("live")
        
        @template = @compile
        @render()

        @updateCompile()

      else
        $("#content").removeClass("live")
        
        @template = -> ""
        @render()
    
    plunker.trigger "event:resize"

    
  render: (context = {}) =>
    @$el.html @template(context)
    @
