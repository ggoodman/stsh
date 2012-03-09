((plunker) ->
  
  sync = (method, model, options = {}) ->
    params = _.extend {}, options,
      url: model.url()
      cache: false
      dataType: "json"

    switch method
      when "create"
        params.type = "post"
        params.headers = "Content-Type": "application/json"
        params.data = JSON.stringify(model.toJSON())
      when "read"
        params.type = "get"
      when "update"
        params.type = "post"
        params.headers = "Content-Type": "application/json"
        params.data = JSON.stringify(model.changes)
      when "delete"
        params.type = "delete"
        
    $.ajax(params)
  
  class plunker.Plunk extends Backbone.Model
    sync: sync
    url: -> @get("url") or "/api/v1/plunks" + if @id then "/#{@id}" else ""
    initialize: ->
      self = @
      
      @set "description", "" unless @get("description")
      @set "files", {} unless @get("files")
      
      @changes = {}
      @on "sync", -> self.changes = {}
      @on "change:description", -> self.changes.description = @get("description")
      @on "change:expires", -> self.changes.expires = @get("expires")
      @on "change:files", ->
        self.changes.files = {}
        self.changes.files[filename] = null for filename, file of self.previous("files")
        
        _.each self.get("files"), (file, filename) -> self.changes.files[filename] ||= file.content or ""
    
    fork: ->
      json =
        description: @get("description")
        files: {}
      
      _.each @get("files"), (file) -> json.files[file.filename] = file.content
      
      @clear()
      @set(json)

  class plunker.PlunkCollection extends Backbone.Collection
    url: -> "/api/v1/plunks"
    model: plunker.Plunk
    comparator: (model) -> -new Cromag(model.get("created_at")).valueOf()
    sync: sync

    import: (source, options = {}) ->
      self = @
      
      for name, matcher of plunker.importers
        if matcher.test(source)
          strategy = matcher
          break;
      
      if strategy
        self.trigger "import:start"
        strategy.import source, (error, json) ->
          json.expires = options.expires if options.expires
          
          if error then self.trigger "import:fail"
          else self.create json, _.defaults options,
            wait: true
            silent: false
            success: -> self.trigger "import:success"
            error: -> self.trigger "import:fail"
      else
        @trigger "error", "Import error", "The source you provided is not a recognized source."
      @
      
)(@plunker ||= {})