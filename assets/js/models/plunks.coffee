((exports) ->
  class exports.Plunk extends Backbone.Model
    defaults:
      description: "Untitled"
    initialize: ->

    toJSON: ->
      json = super()
      json.description ||= "Untitled"
      json

  class exports.PlunkCollection extends Backbone.Collection
    url: -> "/api/v1/plunks"
    model: Plunk
    comparator: (model) -> -new Cromag(model.get("created_at")).valueOf()
    sync: (method, model, options) ->
      params = _.extend {}, options,
        url: @url()
        cache: false
        dataType: "json"

      switch method
        #when "create"
        when "read"
          params.type = "get"

        #when "update"
        when "delete"
          params.type = "delete"

      $.ajax(params)

    import: (source) ->
      self = @

      if matches = source.match(/^(?:(?:https?\:\/\/)?gist\.github\.com\/)?([0-9a-z]+)(?:#.+)?$/)
        self.trigger "import:start"
        promise = $.ajax "https://api.github.com/gists/#{matches[1]}",
          timeout: 8000
          dataType: "jsonp"

        promise.fail -> self.trigger "import:fail"
        promise.done (data) ->
          if data.meta.status >= 400
            self.trigger "import:fail"
            return self.trigger "error", "Import error", "Failed to fetch the requested resource"
          else
            gist = data.data
            self.trigger "import:fetch", data

            json =
              description: gist.description
              source:
                name: "Github"
                url: gist.html_url
              files: {}

            if gist.user then json.author =
              name: gist.user.login
              url: "https://github.com/#{gist.user.login}"

            json.files[filename] = file.content for filename, file of gist.files

            self.create json,
              wait: true
              silent: false
              success: -> self.trigger "import:success"
              error: -> self.trigger "import:fail"
      else
        @trigger "error", "Import error", "The source you provided is not a recognized source."
      @
)(window)