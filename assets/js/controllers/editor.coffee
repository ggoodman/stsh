#= require_tree ../importers
#= require ../lib/modes
#= require ../lib/themes
#= require ../lib/importer
#= require ../lib/compilers
#= require ../models/plunks
#= require ../models/edit_session
#= require ../models/stream
#= require ../models/user
#= require ../views/toolbar
#= require ../views/sidebar
#= require ../views/textarea
#= require ../views/previewer

((plunker) ->

  class plunker.EditorController extends Backbone.Router
    initialize: ->
      self = @
      
      @route /^edit\/from\:([^\?]+)(\?.+)?/, "importPlunk"
      @route /^edit\/([a-zA-Z0-9]{6})(\?.+)?/, "loadPlunk"
      
      @parseQuery()
    
      plunker.user = @user = new plunker.User
      
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
       
      
      
      
      plunker.mediator.on "message", (title, body) -> $.gritter.add
        title: title
        text: body
      
      plunker.mediator.on "event:preview-enable", ->
        self.query.preview = "on"
        delete self.query.live
        self.navigate window.location.pathname,
          replace: true
          trigger: false        
      
      plunker.mediator.on "event:preview-disable", ->
        delete self.query.preview
        self.navigate window.location.pathname,
          replace: true
          trigger: false
          
      plunker.mediator.on "event:live-preview", ->
        self.query.live = "preview"
        self.navigate window.location.pathname,
          replace: true
          trigger: false        

      plunker.mediator.on "event:live-compile", ->
        self.query.live = "compile"
        self.navigate window.location.pathname,
          replace: true
          trigger: false    

      plunker.mediator.on "event:live-off", ->
        delete self.query.live
        self.navigate window.location.pathname,
          replace: true
          trigger: false              
      plunker.mediator.on "event:stream-join event:stream-start", (id) ->
        self.query.stream = id
        self.navigate window.location.pathname,
          replace: true
          trigger: false

      plunker.mediator.on "event:stream-stop", ->
        delete self.query.stream
        self.navigate window.location.pathname,
          replace: true
          trigger: false
          
      if @query.live == "compile" then plunker.mediator.trigger "intent:live-compile"
      else if @query.live == "preview" then plunker.mediator.trigger "intent:live-preview"
      
      if @query.preview == "on" then plunker.mediator.trigger "intent:preview-enable"
      
      if @query.stream then plunker.mediator.trigger "intent:stream-join", @query.stream
      
    navigate: (query, options) ->
      super query + @encodeQuery(), options

    parseQuery: ->
      @query = {};
      
      a = /\+/g
      r = /([^&=]+)=?([^&]*)/g
      d = (s) -> decodeURIComponent(s.replace(a, " "))
      q = window.location.search.substring(1)
      
      @query[d(e[1])] = d(e[2]) while e = r.exec(q)

    encodeQuery: (options) ->
      str = []
      
      options = _.extend {}, @query, options
      
      for k, v of options
        if v != null then str.push(encodeURIComponent(k) + "=" + encodeURIComponent(v))
      
      if str.length then "?" + str.join("&")
      else ""
    
    loadPlunk: (id) -> @session.load(id)
    
    importPlunk: (source) -> @session.import(source)
      
)(@plunker ||= {})