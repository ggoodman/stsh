((exports) ->
  
  #= require_tree ../importers
  
  sync = (method, model, options) ->
    params = _.extend {}, options,
      url: model.url()
      cache: false
      dataType: "json"

    switch method
      when "create"
        params.type = "post"
      when "read"
        params.type = "get"
      when "update"
        params.headers = "Content-Type": "application/json"
        params.type = "post"
        params.data = JSON.stringify(model.changes)
      when "delete"
        params.type = "delete"

    $.ajax(params)
  
  class exports.Plunk extends Backbone.Model
    sync: sync
    url: -> @get("url") or "/api/v1/plunks"
    initialize: ->
      self = @
      @changes = {}
      @on "sync", -> self.changes = {}
      @on "change:description", -> self.changes.description = @get("description")
      @on "change:files", ->
        self.changes.files = {}
        self.changes.files[filename] = null for filename, file of self.previous("files")
        
        _.extend self.changes.files, self.get("files")
    toJSON: ->
      json = super()
      json.description ||= "Untitled"
      json

  class exports.PlunkCollection extends Backbone.Collection
    url: -> "/api/v1/plunks"
    model: Plunk
    comparator: (model) -> -new Cromag(model.get("created_at")).valueOf()
    sync: sync

    import: (source) ->
      self = @
      
      for matcher in plunkSources
        if strategy = matcher(source) then break
      
      if strategy
        self.trigger "import:start"
        strategy source, (error, json) ->
          if error then self.trigger "import:fail"
          else self.create json,
            wait: true
            silent: false
            success: -> self.trigger "import:success"
            error: -> self.trigger "import:fail"
      else
        @trigger "error", "Import error", "The source you provided is not a recognized source."
      @
)(window)