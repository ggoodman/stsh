#= require models/plunks
#= require models/edit_session

#= require views/sidebar
#= require views/toolbar
#= require views/editor

#= require importers/github

window.plunker = _.extend({}, Backbone.Events)

$ ->
  session = new EditSession
  
  toolbar = new Toolbar
    el: document.getElementById("toolbar")
    model: session
  sidebar = new Sidebar
    el: document.getElementById("sidebar")
    model: session
    
  editor = new Editor
    model: session
    
  preview = new Previewer
    el: document.getElementById("preview")
    model: session
    
  importers.github.import "https://gist.github.com/1961272", (error, json) ->
    if error then alert("Unable to fetch default template")
    else
      session.set(json)
      session.buffers.reset(_.values(json.files))
      
      plunker.trigger "activate", "index.html"
