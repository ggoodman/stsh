((exports) ->
  
  class exports.Editor extends Backbone.View
    id: "editor"
    initialize: ->
      self = @
      
      @ace = ace.edit(@id)
      
      plunker.on "activate", (filename) ->
        self.ace.setSession self.model.buffers.get(filename).session
      

)(window)