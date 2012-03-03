((exports) ->
  
  
  HtmlMode = require("ace/mode/html").Mode

  class exports.Editor extends Backbone.View
    id: "editor"
    initialize: ->
      self = @
      
      @ace = ace.edit(@id)
      
      @model.on "change:active", ->
        active = self.model.get("active")
        self.ace.setSession self.model.buffers.get(active).session
      

)(window)