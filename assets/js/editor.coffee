#= require_tree importers
#= require lib/modes
#= require lib/importer
#= require lib/compilers
#= require models/plunks
#= require models/edit_session
#= require views/toolbar
#= require views/sidebar
#= require views/textarea
#= require views/previewer
#= require controllers/editor

((plunker) ->
  
  
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

  
)(@plunker ||= {})