((exports) ->
  
  modes =
    "text/html": require("ace/mode/html").Mode
    #"text/javascript": require("ace/mode/javascript").Mode
    #"text/css": require("ace/mode/css").Mode
  
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
      #@session.setMode(new modes[@get("mime")])
      
      @on "change:content", -> self.session.setValue(self.get("content"))
      #@on "change:mime", -> self.session.setMode(new modes[self.get("mode")])
  
  class exports.BufferCollection extends Backbone.Collection
    model: exports.Buffer
  
  class exports.EditSession extends Backbone.Model
    initialize: ->
      @buffers = new BufferCollection
    
    toJSON: ->
      json = super()
      json.files = @buffers.toJSON()
      console.log "KSON", _.clone(json)
      json

)(window)