((exports) ->
  
  class exports.Editor extends Backbone.View
    id: "editor"
    initialize: ->
      self = @
      
      @ace = ace.edit(@id)

      plunker.on "intent:activate", (filename) ->
        if buffer = self.model.buffers.get(filename)
          self.ace.setSession buffer.session
          plunker.trigger "event:activate", filename

      plunker.on "event:resize", -> self.ace.resize()
      

)(window)