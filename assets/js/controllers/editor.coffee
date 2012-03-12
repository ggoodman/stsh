((plunker) ->

  class plunker.EditorController extends Backbone.Router
    initialize: ->
      @route /^edit\/from\:(.+)$/, "importPlunk"
      @route /^edit\/([a-zA-Z0-9]{6})$/, "loadPlunk"
      
      
      # Model defining the editing session that is taking place on Plunker
      plunker.models.session = @session = new plunker.Session
  
      
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

      plunker.mediator.on "event:reset", ->
        plunker.controller.navigate "/edit",
          replace: false

      plunker.mediator.on "event:save", (plunk) ->
        plunker.controller.navigate "/edit/#{plunk.id}",
          replace: true

    newPlunk: -> @session.reset()
    
    loadPlunk: (id) -> @session.load(id)
    
    importPlunk: (source) -> @session.import(source)
      
)(@plunker ||= {})