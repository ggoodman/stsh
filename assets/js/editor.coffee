!((name, definition) ->
  if typeof module != 'undefined' then module.exports = definition()
  else if typeof define == "function" and define.amd then define name, definition
  else @[name] = definition()
) "plunker", ->
  
  
  $.extend $.gritter.options,
    position: "bottom-right"
  
  plunker = _.defaults (@plunker or {}),
    mediator: _.extend {}, Backbone.Events
    models: {}
    views: {}
    controllers: {}
  
    
  $ ->
    # Controller for the editor environment
    plunker.controller = new plunker.EditorController
    
    plunker.mediator.trigger "intent:reset"
    
    Backbone.history.start
      pushState: true

  
  return plunker