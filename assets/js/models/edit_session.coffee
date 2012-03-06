mappings = [
  ["coffee", "CoffeeScript", ["coffee"]]
  ["css", "CSS", ["css"]]
  ["html", "HTML", ["html", "htm"]]
  ["javascript", "JavaScript", ["js"]]
  ["json", "JSON", ["json"]]
  ["markdown", "Markdown", ["md", "markdown"]]
  ["scss", "SCSS", ["scss"]]
  ["textile", "Textile", ["textile"]]
  ["xml", "XML", ["xml"]]
]

modes = _.map mappings, ([name, title, extensions]) ->
  name: name
  title: title
  regex: new RegExp("^.*\\.(" + extensions.join("|") + ")$", "g")


((exports) ->
  
  EditSession = require("ace/edit_session").EditSession
  
  class exports.Buffer extends Backbone.Model
    idAttribute: "filename"
    initialize: ->
      self = @

      @session = new EditSession(@get("content") or "")
      
      @session.setTabSize(2)
      @session.setUseSoftTabs(true)

      @setMode()
        
      @session.on "change", -> self.set "content", self.session.getValue()

    setMode: ->
      self = @

      if filename = @get("filename")
        _.each modes, (mode) ->
          if mode.regex.test(filename)
            $script "/js/ace/mode-#{mode.name}.js", mode.name
            $script.ready mode.name, ->
              mode.Mode ?= require("ace/mode/#{mode.name}").Mode
              mode.mode ?= new mode.Mode
              self.session.setMode mode.mode



  class exports.BufferCollection extends Backbone.Collection
    model: exports.Buffer
  
  class exports.EditSession extends Backbone.Model
    initialize: ->
      self = @

      @plunk = new Plunk
      @buffers = new BufferCollection
      @queue = []
      
      @buffers.on "add", (model) -> self.queue.unshift model.get("filename")
      @buffers.on "remove", (model) -> self.queue = _.without self.queue, model.get("filename")
      @buffers.on "reset", (coll) -> self.queue = coll.pluck("filename")

      plunker.on "event:activate", (filename) -> self.queue = [filename].concat _.without(self.queue, filename)
      
      plunker.on "intent:save", ->
        json = self.toJSON()
        
        self.plunk.set self.toJSON()
        self.plunk.save {},
          success: (plunk) -> plunker.trigger "event:save", plunk
          error: -> alert("Failed to save plunk")

      plunker.on "intent:fileAdd", (filename) ->
        if filename ?= prompt("Filename?")
          unless self.buffers.get(filename)
            buffer = self.buffers.add
              filename: filename
              content: ""
            plunker.trigger "event:addFile", filename
            plunker.trigger "intent:activate", filename
          else alert "A file named #{filename} already exists."

      plunker.on "intent:fileRemove", (filename = _.first(self.queue)) ->
        if self.buffers.length > 1
          if buffer = self.buffers.get(filename)
            self.buffers.remove buffer
            plunker.trigger "event:removeFile", 
            plunker.trigger "intent:activate", _.first(self.queue)
          else alert "No such file #{filename}."
        else alert "Cannot remove all files from the plunk"


    toJSON: ->
      json = super()
      json.files = {}
      @buffers.each (buffer) ->
        json.files[buffer.id] = buffer.toJSON()
        delete json.files[buffer.id].filename
      json

)(window)

