
_.extend(plunker ?= {}, Backbone.Events)

$ ->
  session = new EditSession
  
  toolbar = new Toolbar
    el: document.getElementById("toolbar")
    model: session

  sidebar = new Sidebar
    el: document.getElementById("sidebar")
    model: session
    
  editor = new Editor
    el: document.getElementById("editor")
    model: session
    
  preview = new Previewer
    el: document.getElementById("preview")
    model: session

  router = new class extends Backbone.Router
    routes:
      "edit":     "loadPlunk"
      "edit/:id": "loadPlunk"

    loadPlunk: (id) ->
      self = @
      
      if id
        plunk = new Plunk(id: id)
        plunk.fetch
          success: ->
            session.buffers.reset _.map plunk.get("files"), (file) ->
              filename: file.filename
              content: file.content
            session.set
              description: plunk.get("description")
  
            plunker.trigger "intent:activate", plunk.get("index")
          error: ->
            router.navigate "",
              trigger: true
              replace: true
      else
        plunker.trigger "intent:fileAdd", "index.html"


  Backbone.history.start
    pushState: true
