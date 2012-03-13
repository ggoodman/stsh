((plunker) ->
  
  class plunker.Textarea extends Backbone.View
    initialize: ->
      self = @
      
      @ace = ace.edit(@id)
      
      @ace.commands.addCommand
        name: "saveFile"
        bindKey:
          win: "Ctrl-S"
          mac: "Command-S"
        exec: (editor) -> plunker.mediator.trigger "intent:save"
      @ace.commands.addCommand
        name: "run"
        bindKey:
          win: "Ctrl-Return"
          mac: "Command-Return"
        exec: (editor) -> plunker.mediator.trigger "intent:preview-enable"

      plunker.mediator.on "intent:activate", @onIntentActivate

      plunker.mediator.on "event:resize", ->
        self.ace.resize()
    
    onIntentActivate: (filename) =>
      if buffer = @model.buffers.get(filename)
        @ace.setSession buffer.session
        @ace.focus()
        
        plunker.mediator.trigger "event:activate", filename
        
      

)(@plunker ||= {})