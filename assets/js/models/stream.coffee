#= require ../lib/sharejs

((plunker) ->
  
  uid = (len = 6, prefix = "", keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") ->
    prefix += keyspace.charAt(Math.floor(Math.random() * keyspace.length)) while len-- > 0
    prefix

  class Channel extends Backbone.Model
    initialize: ->
      self = @
      
      # Remove self from 
      @buffer = plunker.models.session.buffers.get(@get("filename"))
      @buffer.on "remove", @onRemove
      @buffer.on "change:filename", @onChangeFilename
    
    onRemove: (buffer, coll, options) =>
      # Clean up
      @buffer.unbind "remove", @onRemove
      @buffer.unbind "change:filename", @onChangeFilename
      
      coll.remove(@)
    
    onChangeFilename: (buffer, filename, options) => @set "filename", filename
  
  class Channels extends Backbone.Collection
    model: Channel
    initialize: ->
      self = @
      buffers = plunker.models.session.buffers
      
      buffers.on "add", (buffer, coll, options) -> self.add
        id: uid()
        filename: buffer.get("filename")
        
  class plunker.Stream extends Backbone.Model

    initialize: ->
      plunker.mediator.on "intent:stream-start", @onIntentStreamStart
      plunker.mediator.on "intent:stream-join", @onIntentStreamJoin
      plunker.mediator.on "intent:stream-stop", @onIntentStreamStop
      
      @channels = new Channels
      
      @channels.on "add", @onLocalAdd
      #@channels.on "local:remove", @onLocalRemove
      #@channels.on "local:add", @onLocalAdd
    
    onLocalAdd: (channel) =>
      if @share
        @share.at("channels").insert channel.id, channel.toJSON()
    
    init: (@share) ->
      self = @
      
      console.log "Init", arguments...
      
      $channels = @share.at("channels")
      
      console.log "Channels", $channels
      
      #_.each ["change", "insert", "delete", "replace", "move", "child op"], (event) ->
      #  $channels.on event, -> console.log event, arguments...

    
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
            
            self.channels.reset(_.values(channels), remote: true)
          
            # Reset the sharejs doc to the above
            doc.submitOp [ { p: [], od: doc.snapshot, oi: { description: description, channels: channels } } ], (err) ->
              self.init(doc)
    
    # Join an existing stream and create local buffers corresponding to those in the stream
    onIntentStreamJoin: (id) =>
      self = @
      
      console.log "JOIN", _.clone(@), arguments...
      
      @id = id or prompt "Please provide the name of the stream. This should be a hard-to-guess string", uid(6)
      
      if @id
        sharejs.open "state:#{@id}", "json", (err, doc) ->
          if err then plunker.mediator.trigger "ShareJS Error: #{err}"
          else
            buffers = []
            
            self.channels.reset(_.values(doc.snapshot.channels), remote: true)
            self.channels.each (channel) ->
              buffers.push
                filename: channel.get("filename")
                content: ""
            
            plunker.models.session.buffers.reset(buffers, remote: true)
            plunker.models.session.set "description", doc.snapshot.description, remote: true
            
            plunker.mediator.trigger "intent:activate", plunker.models.session.last()
            
            self.init(doc)
            
    
    onIntentStreamStop: =>
      

)(@plunker ||= {})