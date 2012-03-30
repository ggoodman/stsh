#= require ../lib/sharejs

((plunker) ->
  
  uid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix
  
  class plunker.Stream extends Backbone.Model
    initialize: ->
      @share = new sharejs.Connection()
      @session = plunker.models.session
      
      @reset()
      
      plunker.mediator.on "intent:stream-start", @onIntentStreamStart
      plunker.mediator.on "intent:stream-join", @onIntentStreamJoin
      plunker.mediator.on "intent:stream-stop", @onIntentStreamStop
      
      @onLocalChangeDescription = _.throttle @onLocalChangeDescription, 500
    
    onIntentStreamStart: (id) =>
      @create id or prompt "Please provide the id of the stream. Anyone who has this id can join the stream.", uid(16)

    onIntentStreamJoin: (id) =>
      @join id or prompt "Please provide the id of the stream. Anyone who has this id can join the stream.", uid(16)
    
    onIntentStreamStop: =>
      @leave()

  
    getLocalState: ->
      state =
        channels: {}
        description: @session.get("description")
      
      @session.buffers.each (buffer) ->
        id = uid(16)
        state.channels[id] =
          id: id
          filename: buffer.get("filename")
      
      console.log "Local state", state
      
      state
    
    reset: ->
      @channels = 
        byId: {}
        byFilename: {}
    
    leave: ->
      self = @
      
      if @doc
        @doc.close()
        delete @doc
      
      _.each @channels.byId, (channel, id) ->
        channel.close()
      
      @reset()
    
    start: (@doc) ->
      self = @
      console.log "Stream#start", arguments...
      
      ["change", "insert", "delete", "replace", "move", "add", "child op"].forEach (op) ->
        self.doc.on op, -> console.log "REMOTE", op, arguments...
        self.doc.at("description").on op, -> console.log "DESC", op, arguments...

      plunker.models.session.on "change:description", @onLocalChangeDescription
    
    onLocalChangeDescription: (model, value, options) =>
      console.log arguments.callee.name, arguments...
      
      unless options.remote is true
        @doc.at("description").set value
    
    onRemoteChangeDescription: =>
      console.log arguments.callee.name, arguments...
      
      #@session.set "description", 
      
    join: (id) ->
      console.log "Stream#join", arguments...
      self = @
      
      unless id then return plunker.mediator.trigger "error", "plunker.Stream#join missing id"
      
      @id = id

      @share.openExisting "stream:#{@id}", (err, doc) ->
        if err then return plunker.mediator.trigger "message", "Connection error", """
          Failed to join the stream #{id}. Please double-check that you entered
          the right stream id. If the problem persists, please contact the
          administrator.
        """
        
        plunker.models.session.set "description", doc.snapshot.description, remote: true
        plunker.models.session.buffers.reset _.values(_.clone(doc.snapshot.channels)), remote: true
        
        self.start(doc)
        
    create: (id) ->
      console.log "Stream#create", arguments...
      self = @
      
      unless id then return plunker.mediator.trigger "error", "plunker.Stream#create missing id"
      
      @id = id

      @share.open "stream:#{@id}", "json", (err, doc) ->
        if err then return plunker.mediator.trigger "message", "Connection error", """
          Failed to start the stream #{id}; please try again.
          If the problem persists, please contact the administrator.
        """
        
        # Reset the channel to the current local state
        doc.submitOp [ { p: [], od: doc.snapshot, oi: self.getLocalState() } ], (err) ->
          if err then plunker.mediator.trigger "error", "Error setting initial state"
          else self.start(doc)

  ###
  class Channel extends Backbone.Model
    initialize: (options) ->
      self = @
      
      console.log "Ooptions", arguments...
      
      if buffer = plunker.models.session.buffers.get(@get("filename"))
        @session = buffer.session
        
        console.log "BUFFER", buffer
        
        sharejs.open @get("stream") + ":" + @id, "text", (err, doc) ->
          doc.attach_ace self.session.getDocument()
      
      self = @
    
  
  class Channels extends Backbone.Collection
    model: Channel
    initialize: ->
      self = @

      buffers = plunker.models.session.buffers
      
      # Proxy remote Channel events to the Session's Buffers
      
      @on "reset", (coll, options) ->
        console.log "ONRESET", arguments...
        if options.remote is true and coll.length > 0
          buffs = []
          coll.each (channel) ->
            buffs.push 
              filename: channel.get("filename")
              content: "Loading..."
          buffers.reset buffs, remote: true
          plunker.mediator.trigger "intent:activate", plunker.models.session.last()
      
      @on "add", (channel, coll, options) ->
        console.log "Channels::add", arguments...
        if options.remote is true
          buffer = 
            filename: channel.get("filename")
            content: "Loading..."
          buffers.add buffer, remote: true
      
      @on "remove", (channel, coll, options) ->
        if options.remote is true
          if buffer = buffers.get(channel.get("filename"))
            buffers.remove buffer, remote: true
      
      @on "change:filename", (channel, filename, options) ->
        if options.remote is true
          if buffer = buffers.get(channel.previous("filename"))
            buffer.set "filename", filename
      
      # Proxy local events from the Session to the Channel
      
      buffers.on "add", (buffer, coll, options) ->
        unless options.remote is true then self.add
          id: uid()
          filename: buffer.get("filename")
          stream: self.stream.id
      
      buffers.on "remove", (buffer, coll, options) ->
        unless options.remote is true
          if channel = self.channels.find((c) -> c.get("filename") == buffer.get("filename"))
            channels.remove channel
      
      buffers.on "change:filename", (buffer, filename, options) ->
        unless options.remote is true
          if channel = self.channels.find((c) -> c.get("filename") == buffer.previous("filename"))
            channel.set "filename", filename
        
  class plunker.Stream extends Backbone.Model

    initialize: ->
      self = @
      
      plunker.mediator.on "intent:stream-start", @onIntentStreamStart
      plunker.mediator.on "intent:stream-join", @onIntentStreamJoin
      plunker.mediator.on "intent:stream-stop", @onIntentStreamStop
      
      @channels = new Channels
      @channels.stream = @
      
      @channels.on "add", @onAdd
      @channels.on "remove", @onRemove
      @channels.on "change:filename", @onRename
      
      @channels.on "reset", (coll, options) ->
        console.log "Resetting", self, arguments...
        coll.each (channel) -> self.onAdd(channel, coll, options)
    
    toJSON: ->
      json = super()
      json.channels = {}
      @channels.each (channel) -> json.channels[channel.id] = channel.toJSON()
      json
    
    onAdd: (channel, coll, options) =>
      if @share and options.remote isnt true
        @share.at(["channels", channel.id]).set channel.toJSON()

    onRemove: (channel, coll, options) =>
      if @share and options.remote isnt true
        @share.at(["channels", channel.id]).remove()

    onRename: (channel, filename, options) =>
      if @share and options.remote isnt true
        @share.at(["channels", channel.id]).set filename
        
    init: (@share) ->
      self = @
      
      $channels = @share.at("buffers")
      
      $channels.on "child op", (id, e) ->
        if e.oi
          self.channels.add e.oi, remote: true
      
      _.each ["change", "insert", "delete", "replace", "move", "child op"], (event) ->
        $channels.on event, -> console.log event, arguments...

    
    # Start a new stream and define the buffers of that stream
    onIntentStreamStart: (id) =>
      self = @
      
      @id = id or prompt "Please provide the name of the stream. This should be a hard-to-guess string", uid(6)
      
      if @id
        sharejs.open "state:#{@id}", "json", (err, doc) ->
          if err then plunker.mediator.trigger "ShareJS Error: #{err}"
          else
            # Take current buffers and create a hash of UID => filename
            channels = {}
            session = plunker.models.session
            description = session.get("description")
            
            session.buffers.each (buffer) ->
              id = uid()
              channels[id] =
                id: id
                filename: buffer.get("filename")
                stream: self.id
            
            self.clear()
            self.channels.reset(_.values(channels))
            self.set "description", description
          
            # Reset the sharejs doc to the above
            doc.submitOp [ { p: [], od: doc.snapshot, oi: self.toJSON() } ], (err) ->
              self.init(doc)
    
    # Join an existing stream and create local buffers corresponding to those in the stream
    onIntentStreamJoin: (id) =>
      self = @
      
      @id = id or prompt "Please provide the name of the stream. This should be a hard-to-guess string", uid(6)
      
      if @id
        sharejs.open "state:#{@id}", "json", (err, doc) ->
          if err then plunker.mediator.trigger "ShareJS Error: #{err}"
          else
            self.channels.reset(_.values(_.clone(doc.snapshot.channels)), remote: true)
            self.set "description", doc.snapshot.description, remote: true
            
            self.init(doc)
            
    
    onIntentStreamStop: =>
  ###

)(@plunker ||= {})