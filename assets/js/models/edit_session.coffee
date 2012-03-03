((exports) ->
  
  modes = {}
  modes["text/html"] = require("ace/mode/html").Mode
  modes["text/javascript"] = require("ace/mode/javascript").Mode
  modes["text/css"] = require("ace/mode/css").Mode
  modes["application/javascript"] = modes["text/javascript"]
  
  EditSession = require("ace/edit_session").EditSession
  
  class exports.Buffer extends Backbone.Model
    idAttribute: "filename"
    initialize: ->
      self = @

      @session = new EditSession(@get("content") or "")
      
      @session.setTabSize(2)
      @session.setUseSoftTabs(true)
      
      if mode = modes[@get("mime")]
        @session.setMode new mode()
        
      @session.on "change", ->
        self.set "content", self.session.getValue()
        
  class exports.BufferCollection extends Backbone.Collection
    model: exports.Buffer
  
  class exports.EditSession extends Backbone.Model
    initialize: ->
      @buffers = new BufferCollection
    
    toJSON: ->
      json = super()
      json.files = {}
      @buffers.each (buffer) ->
        json.files[buffer.id] = buffer.toJSON()
        delete json.files[buffer.id].filename
      json

)(window)