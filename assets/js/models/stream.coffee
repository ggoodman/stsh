#= require ../lib/sharejs

((plunker) ->
  
  uid = (len = 16, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix

  
  class plunker.Stream extends Backbone.Model
    initialize: ->
      self = @
      
      @session = plunker.models.session
      @local = _.extend {}, Backbone.Events
      @remote = _.extend {}, Backbone.Events
      
      @channels = {}
      
      @watchSession()
      
      @bindLocalEvents()
      @bindRemoteEvents()
      
      # Handle interface intents for streaming
      plunker.mediator.on "intent:stream-start", (id) ->
        self.join id or prompt "Please provide the id of the stream. Anyone who has this id can join the stream.", uid(16)
      plunker.mediator.on "intent:stream-join", (id) ->
        self.join id or prompt "Please provide the id of the stream. Anyone who has this id can join the stream."
      plunker.mediator.on "intent:stream-stop", (id) ->
        self.stop()
        
      plunker.mediator.on "event:stream-join", (id) ->
        $.gritter.add
          title: "Joined stream: #{id}"
          text: """
            <p>All changes you make to your current edit session will be shared
            with everyone else in the same stream.</p>
            <p>Note that saving the editor's state will not affect the stream.
            Similarly, if you save the state, that plunk will not be tied to the
            stream.</p>
          """
      
      plunker.mediator.on "event:stream-start", (id) ->
        $.gritter.add
          title: "Started stream: #{id}"
          text: """
            <p>All changes you make to your current edit session will be shared
            with everyone else in the same stream.</p>
            <p>Note that saving the editor's state will not affect the stream.
            Similarly, if you save the state, that plunk will not be tied to the
            stream.</p>
          """
      
      # Throttle local events
      _.each ["onLocalChangeDescription"], (method) ->
        self[method] = _.throttle self[method], 500
    
    getConnection: ->
      location = window.location
      @conn ||= new sharejs.Connection("#{location.protocol}//#{location.host}/channel")
    
    watchSession: ->
      self = @
      
      # Proxy changes to the session to the local emitter
      @session.on "change:description", (model, value, options) ->
        unless options.remote is true
          self.local.trigger "description:change", value, options
      
      # Proxy local buffer events to the local emitter
      @session.buffers.on "reset", (coll, options) ->
        unless options.remote is true
          self.local.trigger "buffers:reset", coll, _.extend options,
            keep: true
        
        if self.doc
          _.each self.channels, (channel) -> self.unwatch channel.buffer
          coll.each (buffer) -> self.watch(buffer, keep: options.remote != true)
          
      @session.buffers.on "add", (model, coll, options) ->
        unless options.remote is true
          self.local.trigger "buffers:add", model, options
        if self.doc then self.watch(model, options)
      @session.buffers.on "remove", (model, coll, options) ->
        unless options.remote is true
          self.local.trigger "buffers:remove", model, options
        if self.doc then self.unwatch(model, options)
      @session.buffers.on "change:filename", (model, value, options) ->
        unless options.remote is true
          self.local.trigger "buffers:rename", model, options

    bindLocalEvents: ->
      self = @
      
      # Send local changes to the description over sharejs
      @local.on "description:change", (description) ->
        if self.doc then self.doc.at("description").set description
        
      # Reset the entire channel object and send over sharejs
      @local.on "buffers:reset", (buffers) ->
        if self.doc then self.doc.at(["channels"]).set self.getLocalState().channels
      
      # Add new buffer to sharejs channels object
      @local.on "buffers:add", (buffer, options) ->    
        if self.doc
          id = uid(16)
          buffer.set "channel", id
          self.doc.at(["channels", id]).set
            channel: id
            filename: buffer.get("filename")

      # Remove buffer from sharejs channels object
      @local.on "buffers:remove", (buffer) ->
        if self.doc then self.doc.at(["channels", buffer.get("channel")]).remove()
        
      @local.on "buffers:rename", (buffer) ->
        if self.doc then self.doc.at(["channels", buffer.get("channel"), "filename"]).set buffer.get("filename")
    
    bindRemoteEvents: ->
      self = @
      
      @remote.on "description:change", (description, options = {}) ->
        self.session.set "description", description, remote: true
      
      @remote.on "channels:reset", (channels, options = {}) ->
        self.session.buffers.reset _.values(_.clone(channels)), remote: true, keep: options.keep
      
      @remote.on "channels:add", (channel, options = {}) ->
        unless self.session.buffers.get(channel.filename)
          self.session.buffers.add channel, remote: true
      
      @remote.on "channels:remove", (channel, options = {}) ->
        self.session.buffers.remove channel.filename, remote: true
      
      @remote.on "channels:rename", (filename, old_filename, options = {}) ->
        if buffer = self.session.buffers.get(old_filename)
          buffer.set "filename", filename, remote: true
    
    watch: (buffer, options = {}) ->
      self = @
      
      conn = @getConnection()
      
      conn.open "channel:#{@id}:#{buffer.get('channel')}", "text", (err, doc) ->
        if err then return plunker.mediator.trigger "message", "Connection error", """
          Failed to join the stream #{id}. Please double-check that you entered
          the right stream id. If the problem persists, please contact the
          administrator.
        """
        
        self.channels[buffer.get("channel")] =
          doc: doc
          buffer: buffer
        
        doc.attach_ace buffer.session.getDocument(), options.keep == true
    
    unwatch: (buffer) ->
      id = buffer.get("channel")
      if @channels[id]
        @channels[id].doc.detach_ace()
        
        delete @channels[id]
        
    stop: ->
      self = @
      
      @doc.close()
      
      _.each @channels, (channel) ->
        self.unwatch(channel.buffer)
      
      @conn.disconnect()
      
      delete @id
      delete @doc
      delete @conn
      
      plunker.mediator.trigger "event:stream-stop"
      
    start: (@id, @doc) ->
      self = @
        
      @doc.on "change", (events) ->
        _.each events, (e) ->
          if e.p.length then switch e.p[0]
            when "description" then self.remote.trigger "description:change", e.oi or ""
            when "channels"
              # TODO: This first comparison is VERY inefficient
              if e.p.length == 1 and not _.isEqual(self.getLocalState().channels, e.oi) then self.remote.trigger "channels:reset", e.oi
              else if e.p.length == 2
                if e.od? then self.remote.trigger "channels:remove", e.od
                else if e.oi? then self.remote.trigger "channels:add", e.oi
              else if e.p.length == 3
                self.remote.trigger "channels:rename", e.oi, e.od, e.p[2]
          else
            self.remote.trigger "description:change", e.oi.description
            self.remote.trigger "channels:reset", e.oi.channels, keep: false

  
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
      
      state
      
    join: (id) ->
      self = @
      
      unless id then return plunker.mediator.trigger "error", "plunker.Stream#join missing id"
      
      plunker.mediator.trigger "event:disable"

      @getConnection().open "stream:#{id}", "json", (err, doc) ->
        if err then return plunker.mediator.trigger "message", "Connection error", """
          Failed to join the stream #{id}. Please double-check that you entered
          the right stream id. If the problem persists, please contact the
          administrator.
        """
        
        if doc.created is true
          # Reset the channel to the current local state
          doc.submitOp [ { p: [], od: doc.snapshot, oi: self.getLocalState() } ], (err) ->
            if err then plunker.mediator.trigger "error", "Error setting initial state"
            else
              self.start(id, doc)
              self.session.buffers.each (buffer) -> self.watch(buffer, keep: true)
              plunker.mediator.trigger "event:stream-start", id
              plunker.mediator.trigger "event:enable"
        else
          self.start(id, doc)

          self.remote.trigger "description:change", doc.snapshot.description, ""
          self.remote.trigger "channels:reset", doc.snapshot.channels, keep: true
  
          plunker.mediator.trigger "event:stream-join", id
          plunker.mediator.trigger "event:enable"

)(@plunker ||= {})