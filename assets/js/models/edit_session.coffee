((plunker) ->
  # Ace editor session
  EditSession = require("ace/edit_session").EditSession
  

  # Model to represent a text buffer in a Plunker session
  class plunker.Buffer extends Backbone.Model
    idAttribute: "filename"
    initialize: ->
      self = @

      @session = new EditSession(@get("content") or "")
      
      @session.setTabSize(2)
      @session.setUseSoftTabs(true)
      
      @set("filename", "Untitled-#{@cid}.txt") unless @id

      @setMode()
        
      @on "change:filename", @setMode
      
      @session.on "change", -> self.set "content", self.session.getValue()       
    
    toJSON: ->
      filename: @get("filename")
      content: @session.getValue() or ""

    setMode: =>
      self = @
      plunker.modes.loadByFilename @get("filename"), (mode) ->
        if mode
          self.mode = mode
          self.session.setMode(mode.mode)
  
  class plunker.BufferCollection extends Backbone.Collection
    model: plunker.Buffer
    toJSON: ->
      json = {}
      
      @each (buffer) -> json[buffer.id] = buffer.toJSON()
      
      
  class plunker.Session extends Backbone.Model
    initialize: ->
      self = @

      @plunk = new plunker.Plunk
      @buffers = new plunker.BufferCollection
      @queue = []
      
      @buffers.on "add", (model) -> self.queue.unshift model.get("filename")
      @buffers.on "remove", (model) -> self.queue = _.without self.queue, model.get("filename")
      @buffers.on "reset", (coll) -> self.queue = coll.pluck("filename")

      plunker.mediator.on "event:activate", (filename) -> self.queue = [filename].concat _.without(self.queue, filename)
      plunker.mediator.on "event:load:start", -> $("#wrap").addClass("loading")
      plunker.mediator.on "event:load:end", -> $("#wrap").removeClass("loading")
      
      plunker.mediator.on "intent:save", @onIntentSave
      plunker.mediator.on "intent:fileAdd", @onIntentFileAdd
      plunker.mediator.on "intent:fileRemove", @onIntentFileRemove
      plunker.mediator.on "intent:reset", @reset

    
    last: -> _.first(@queue)
    
    toJSON: ->
      json =
        description: @get("description")
        index: @get("index")
        files: {}
        
      @buffers.each (buffer) -> json.files[buffer.id] =
        filename: buffer.id
        content: buffer.get("content")
        
      json
        
    onIntentSave: =>
      @plunk.set @toJSON()
      @plunk.save {},
        success: (plunk) -> plunker.mediator.trigger "event:save", plunk
        error: -> alert("Failed to save plunk")

    
    onIntentFileAdd: (filename) =>
      if filename ?= prompt("Filename?")
        unless @buffers.get(filename)
          buffer = @buffers.add
            filename: filename
            content: ""
          plunker.mediator.trigger "event:addFile", filename
          plunker.mediator.trigger "intent:activate", filename
        else alert "A file named #{filename} already exists."

    onIntentFileRemove: (filename) =>
      if @buffers.length > 1
        filename ||= @last()
        if buffer = @buffers.get(filename)
          if confirm "Are you sure that you want to delete the file #{filename}?"
            @buffers.remove buffer
            plunker.mediator.trigger "event:removeFile", 
            plunker.mediator.trigger "intent:activate", @last()
        else alert "No such file #{filename}."
      else alert "Cannot remove all files from the plunk"
      
    
    import: (source) ->
      session = @

      plunker.mediator.trigger "event:load:start"

      @plunk.clear()
      @buffers.reset()
      @clear()

      plunker.controller.navigate "/edit",
        replace: true
        trigger: false

      plunker.import source,
        success: (json) ->
          session.buffers.reset _.values(json.files)
          
          session.set
            index: json.index
            description: json.description
            
          plunker.mediator.trigger "event:load:end"
          plunker.mediator.trigger "intent:activate", json.index
        error: ->
          alert "Failed to fetch plunk"
          plunker.controller.navigate "/edit",
            trigger: true
            replace: true
          plunker.mediator.trigger "event:load:end"                      

    load: (id) ->
      session = @

      @plunk.clear()
      @buffers.reset()
      @clear()
      
      plunker.mediator.trigger "event:load:start"
      
      if id then @plunk
        .set("id", id)
        .fetch
          success: (plunk) ->
            session.buffers.reset _.values(plunk.get("files"))
            session.set
              index: plunk.get("index")
              description: plunk.get("description")
                        
            unless plunk.get("token")
              plunk.fork()
              
              plunker.controller.navigate "/edit",
                replace: true
                
            plunker.mediator.trigger "event:load:end"
            plunker.mediator.trigger "intent:activate", plunk.get("index")
          error: ->
            alert "Failed to fetch plunk"
            plunker.controller.navigate "/edit",
              trigger: true
              replace: true
            plunker.mediator.trigger "event:load:end"
    
    reset: =>
      console.log "reset"
      @plunk.clear()
      @buffers.reset()
      @clear()
      
      plunker.mediator.trigger "event:reset"
      
      plunker.mediator.trigger "intent:fileAdd", "index.html"

)(@plunker ||= {})