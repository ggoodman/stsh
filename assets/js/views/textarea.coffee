((plunker) ->
  
  class plunker.Textarea extends Backbone.View
    initialize: ->
      self = @
      
      @ace = ace.edit(@id)

      plunker.mediator.on "intent:activate", @onIntentActivate

      plunker.mediator.on "event:resize", ->
        self.ace.resize()
    
    onIntentActivate: (filename) =>
      if buffer = @model.buffers.get(filename)
        @ace.setSession buffer.session
        @ace.focus()
        
        plunker.mediator.trigger "event:activate", filename
        
      

)(@plunker ||= {})