((plunker) ->
  # Ace editor session
  EditSession = require("ace/edit_session").EditSession
  UndoManager = require("ace/undomanager").UndoManager
  

  # Model to represent a text buffer in a Plunker session
  class plunker.Buffer extends Backbone.Model
    idAttribute: "filename"
    initialize: ->
      self = @

      @session = new EditSession(@get("content") or "")
      
      @session.setTabSize(2)
      @session.setUseSoftTabs(true)
      @session.setUndoManager(new UndoManager())
      
      @set("filename", "Untitled-#{@cid}.txt") unless @id

      @setMode()
        
      @on "change:filename", @setMode
      
      @session.on "change", -> self.set "content", self.session.getValue()       
    
    toJSON: ->
      filename: @get("filename")
      content: @session.getValue() or ""
    
    enableShare: (id) ->
      self = @
      
      sharejs.open "#{id}/#{@id}", "text", (err, doc) ->
        if err then plunker.mediator.trigger "error", "ShareJS Error: #{err}"
        else
          doc.attach_ace self.session.getDocument()

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
      
      #plunker.mediator.on "event:fileRename", (to, from) -> self.queue = _.map self.queue, (el) -> if el == from then to else el
      plunker.mediator.on "event:activate", (filename) -> self.queue = [filename].concat _.without(self.queue, filename)
      plunker.mediator.on "event:load:start", -> $("#wrap").addClass("loading")
      plunker.mediator.on "event:load:end", -> $("#wrap").removeClass("loading")

      plunker.mediator.on "event:reset", ->
        plunker.controller.navigate "/edit",
          replace: false

      plunker.mediator.on "event:save", (plunk) ->
        $.gritter.add
          title: "Plunk saved"
          text: """
            The plunk '#{plunk.get("description")}' has been saved.
            <ul>
              <li><a href="#{plunk.get("html_url")}">Fullscreen URL</a></li>
              <li><a href="#{document.location}">Edit URL</a></li>
            </ul>
          """
        plunker.controller.navigate "/edit/#{plunk.id}",
          replace: true

      plunker.mediator.on "event:delete", (plunk) ->
        $.gritter.add
          title: "Plunk deleted"
          text: """
            The plunk '#{plunk.get("description")}' has been deleted.
          """
        
        plunker.mediator.trigger "intent:reset"

      plunker.mediator.on "intent:save", @onIntentSave
      plunker.mediator.on "intent:delete", @onIntentDelete
      plunker.mediator.on "intent:reset", @onIntentReset
      plunker.mediator.on "intent:fileAdd", @onIntentFileAdd
      plunker.mediator.on "intent:fileRemove", @onIntentFileRemove
      plunker.mediator.on "intent:fileRename", @onIntentFileRename
    
    last: -> _.first(@queue)
    getActiveBuffer: -> @buffers.get(@last())
    
    guessIndex: ->
      filenames = @buffers.pluck("filename")

      if "index.html" in filenames then "index.html"
      else
        html = _.filter filenames, (filename) -> /.html?$/.test(filename)

        if html.length then html[0]
        else filenames[0]
    
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
        error: -> $.gritter.add
          title: "Save failed"
          text: """
            Failed to save the plunk. Please try again.
            If the problem persists, please <a href="https://twitter.com/intent/tweet?url=plunker.no.de&hashtags=Bug">report</a> the problem.
          """
        
    onIntentDelete: =>
      if confirm "Are you sure that you want to delete this plunk?"
        @plunk.destroy
          success: (plunk) -> plunker.mediator.trigger "event:delete", plunk
          error: -> $.gritter.add
            title: "Delete failed"
            text: """
              Failed to delete the plunk. Please try again.
              If the problem persists, please <a href="https://twitter.com/intent/tweet?url=plunker.no.de&hashtags=Bug">report</a> the problem.
            """

    
    onIntentFileAdd: (filename) =>
      if filename ||= prompt("Filename?")
        unless @buffers.get(filename)
          buffer = @buffers.add
            filename: filename
            content: ""
          plunker.mediator.trigger "event:addFile", filename
          plunker.mediator.trigger "intent:activate", filename
        else $.gritter.add
          title: "File add failed"
          text: "A file named #{filename} already exists."

    onIntentFileRemove: (filename) =>
      if @buffers.length > 1
        filename ||= @last()
        if buffer = @buffers.get(filename)
          if confirm "Are you sure that you want to delete the file #{filename}?"
            @buffers.remove buffer
            plunker.mediator.trigger "event:removeFile", filename
            plunker.mediator.trigger "intent:activate", @last()
        else $.gritter.add
          title: "Remove failed"
          text: "No such file #{filename}."
      else $.gritter.add
        title: "Remove failed"
        text: "Unabled to remove all files from a plunk. Please add a second file before removing this one."

    onIntentFileRename: (filename, new_filename) =>
      if buffer = @buffers.get(filename)
        if new_filename ||= prompt("New filename?")
          @queue = _.map @queue, (el) -> if el == filename then new_filename else filename
          buffer.set "filename", new_filename
          plunker.mediator.trigger "event:fileRename", new_filename, filename
      else $.gritter.add
        title: "Rename failed"
        text: "The buffer being renamed couldn't be found"
        
    onIntentReset: (options = {}) =>
      @plunk.clear()
      @buffers.reset(options.buffers or [])
      @clear()
      
      @set
        description: options.description or "Untitled"
      
      plunker.mediator.trigger "event:reset"
      plunker.mediator.trigger "intent:fileAdd", "index.html" unless @buffers.length
    
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
            
          plunker.mediator.trigger "intent:activate", json.index
          plunker.mediator.trigger "event:load:end"
          plunker.mediator.trigger "event:import", json, source
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
                
            plunker.mediator.trigger "intent:activate", plunk.get("index")
            plunker.mediator.trigger "event:load:end"
            plunker.mediator.trigger "event:load", plunk
          error: ->
            alert "Failed to fetch plunk"
            plunker.controller.navigate "/edit",
              trigger: true
              replace: true
            plunker.mediator.trigger "event:load:end"
    

)(@plunker ||= {})