#= require ../lib/sharejs

((plunker) ->
  
  uid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix

  
  class plunker.Stream extends Backbone.Model
    initialize: ->
      self = @
      
      @share = new sharejs.Connection()
      @session = plunker.models.session
      @local = _.extend {}, Backbone.Events
      @remote = _.extend {}, Backbone.Events
      
      @watchSession()
      
      @bindLocalEvents()
      @bindRemoteEvents()
      
      # Handle interface intents for streaming
      plunker.mediator.on "intent:stream-start", (id) ->
        self.create id or prompt "Please provide the id of the stream. Anyone who has this id can join the stream.", uid(16)
      plunker.mediator.on "intent:stream-join", (id) ->
        self.join id or prompt "Please provide the id of the stream. Anyone who has this id can join the stream.", uid(16)
      plunker.mediator.on "intent:stream-stop", (id) ->
        self.stop()
      
      # Throttle local events
      _.each ["onLocalChangeDescription"], (method) ->
        self[method] = _.throttle self[method], 500
    
    watchSession: ->
      self = @
      
      # Proxy changes to the session to the local emitter
      @session.on "change:description", (model, value, options) ->
        unless options.remote is true
          self.local.trigger "description:change", value, options
      
      # Proxy local buffer events to the local emitter
      @session.buffers.on "reset", (coll, options) ->
        unless options.remote is true
          self.local.trigger "buffers:reset", coll
      @session.buffers.on "add", (model, coll, options) ->
        unless options.remote is true
          self.local.trigger "buffers:add", model
      @session.buffers.on "remove", (model, coll, options) ->
        unless options.remote is true
          self.local.trigger "buffers:remove", model
      @session.buffers.on "change:filename", (model, value, options) ->
        unless options.remote is true
          self.local.trigger "buffers:rename", model

    bindLocalEvents: ->
      self = @
      
      # Send local changes to the description over sharejs
      @local.on "description:change", (description) ->
        if self.doc then self.doc.at("description").set description
        
      # Reset the entire channel object and send over sharejs
      @local.on "buffers:reset", (buffers) ->
        if self.doc then self.doc.at(["channels"]).set self.getLocalState().channels
      
      # Add new buffer to sharejs channels object
      @local.on "buffers:add", (buffer) ->    
        if self.doc
          id = uid(16)
          self.doc.at(["channels", id]).set
              channel: id
              filename: buffer.get("filename")
            , -> buffer.set "channel", id
      
      # Remove buffer from sharejs channels object
      @local.on "buffers:remove", (buffer) ->
        if self.doc then self.doc.at(["channels", buffer.get("channel")]).remove()
        
      @local.on "buffers:rename", (buffer) ->
        if self.doc then self.doc.at(["channels", buffer.get("channel"), "filename"]).set buffer.get("filename")
    
    bindRemoteEvents: ->
      self = @
      
      @remote.on "description:change", (description) ->
        self.session.set "description", description, remote: true
      
      @remote.on "channels:reset", (channels) ->
        self.session.buffers.reset _.values(_.clone(channels)), remote: true
        plunker.mediator.trigger "intent:activate", self.session.guessIndex()
      
      @remote.on "channels:add", (channel) ->
        self.session.buffers.add channel, remote: true
      
      @remote.on "channels:remove", (channel) ->
        self.session.buffers.remove channel.filename, remote: true
      
      @remote.on "channels:rename", (filename, old_filename) ->
        if buffer = self.session.buffers.get(old_filename)
          buffer.set "filename", filename, remote: true
      
    
    stop: ->
      @doc.close()
      
      delete @id
      delete @doc
    
    start: (@id, @doc) ->
      self = @
      
      @doc.at("channels").on "insert", (id, channel) -> self.remote.trigger "channels:add", channel
      
      @doc.at("channels").on "delete", (id, channel) -> self.remote.trigger "channels:remove", channel
        
      @doc.on "change", (events) ->
        _.each events, (e) ->
          switch e.p.join(".")
            when "description" then self.remote.trigger "description:change", e.oi or ""
            when "channels" then self.remote.trigger "channels:reset", _.values(_.clone(self.doc.snapshot.channels))
      
      @doc.at("channels").on "child op", (p, op) ->
        self.remote.trigger "channels:rename", op.oi, op.od

  
    getLocalState: ->
      state =
        channels: {}
        description: @session.get("description")
      
      @session.buffers.each (buffer) ->
        unless id = buffer.get("channel")
          id = uid(16)
          buffer.set "channel", id
          
        state.channels[id] =
          channel: id
          filename: buffer.get("filename")
        
      console.log "Local state", state
      
      state
      
    join: (id) ->
      self = @
      
      unless id then return plunker.mediator.trigger "error", "plunker.Stream#join missing id"

      sharejs.open "stream:#{id}", "json", (err, doc) ->
        if err then return plunker.mediator.trigger "message", "Connection error", """
          Failed to join the stream #{id}. Please double-check that you entered
          the right stream id. If the problem persists, please contact the
          administrator.
        """
        
        console.log "joined", id, arguments...
        
        self.remote.trigger "description:change", doc.snapshot.description, ""
        self.remote.trigger "channels:reset", doc.snapshot.channels

        self.start(id, doc)
        
    create: (id) ->
      self = @
      
      unless id then return plunker.mediator.trigger "error", "plunker.Stream#create missing id"

      @share.open "stream:#{id}", "json", (err, doc) ->
        if err then return plunker.mediator.trigger "message", "Connection error", """
          Failed to start the stream #{id}; please try again.
          If the problem persists, please contact the administrator.
        """
        
        console.log "started", id, arguments...
        
        # Reset the channel to the current local state
        doc.submitOp [ { p: [], od: doc.snapshot, oi: self.getLocalState() } ], (err) ->
          if err then plunker.mediator.trigger "error", "Error setting initial state"
          else self.start(id, doc)

)(@plunker ||= {})