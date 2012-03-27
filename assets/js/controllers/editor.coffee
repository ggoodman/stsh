#= require_tree ../importers
#= require ../lib/modes
#= require ../lib/themes
#= require ../lib/importer
#= require ../lib/compilers
#= require ../models/plunks
#= require ../models/edit_session
#= require ../models/stream
#= require ../views/toolbar
#= require ../views/sidebar
#= require ../views/textarea
#= require ../views/previewer

((plunker) ->

  class plunker.EditorController extends Backbone.Router
    initialize: ->
      @route /^edit\/from\:(.+)$/, "importPlunk"
      @route /^edit\/([a-zA-Z0-9]{6})$/, "loadPlunk"
      
      
      # Model defining the editing session that is taking place on Plunker
      plunker.models.session = @session = new plunker.Session
  
      plunker.models.stream = @stream = new plunker.Stream
      
      # View for the toolbar at the top of the page
      plunker.views.toolbar = new plunker.Toolbar
        el: document.getElementById("toolbar")
        model: plunker.models.session

      # View for the sidebar
      plunker.views.sidebar = @sidebar = new plunker.Sidebar
        el: document.getElementById("sidebar")
        model: plunker.models.session
      
      # View for the text editor component
      plunker.views.textarea = @textarea = new plunker.Textarea
        id: "textarea"
        model: plunker.models.session

      # View for the live previewer component
      plunker.views.previewer = new plunker.Previewer
       el: document.getElementById("live")
       model: plunker.models.session

    
    loadPlunk: (id) -> @session.load(id)
    
    importPlunk: (source) -> @session.import(source)
      
)(@plunker ||= {})