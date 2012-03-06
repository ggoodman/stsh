
_.extend(plunker ?= {}, Backbone.Events)

urlParams = {}

do ->
  a = /\+/g
  r = /([^&=]+)=?([^&]*)/g
  d = (s) -> decodeURIComponent(s.replace(a, " "))
  q = window.location.search.substring(1)
  
  while e = r.exec(q)
    urlParams[d(e[1])] = d(e[2])
    
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
      "edit":                 "loadPlunk"
      "edit/from::source":  "importPlunk"
      "edit/:id":             "loadPlunk"
    
    initialize: ->
      plunker.on "event:save", (plunk) ->
        router.navigate "/edit/#{plunk.id}",
          trigger: false
          replace: true
    
    getOptions: (options = {}) ->
      self = @
      
      _.defaults options,
        success: (plunk) ->
          session.buffers.reset _.map plunk.get("files"), (file) ->
            filename: file.filename
            content: file.content
          session.set
            description: plunk.get("description")
          
          unless plunk.get("token")
            plunk.unset("id")
            plunk.unset("url")
            plunk.unset("raw_url")
            plunk.unset("html_url")
            plunk.unset("created_at")
            plunk.unset("updated_at")

            router.navigate "/edit",
              trigger: false
              replace: true
  
          plunker.trigger "intent:activate", plunk.get("index")
        error: ->
          router.navigate "/edit",
            trigger: true
            replace: true

    loadPlunk: (id) ->
      console.log "loadPlunk", arguments...
      if id
        session.plunk.set(id: id)
        session.plunk.fetch @getOptions()

      else
        plunker.trigger "intent:fileAdd", "index.html"
    
    importPlunk: (source) ->
      options = @getOptions()
      
      router.navigate "/edit",
        trigger: false
        replace: true
      
      if source
        coll = new PlunkCollection()
        coll.import source, options
      else options.error()


  Backbone.history.start
    pushState: true
