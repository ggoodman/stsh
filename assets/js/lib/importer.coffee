((plunker) ->

  plunker.import = (source, options = {}) ->
    self = @
    
    options = _.defaults options,
      wait: true
      silent: false
      defaults: {}
      plunk: new plunker.Plunk
      success: ->
      error: ->
    
    for name, matcher of plunker.importers
      if matcher.test(source)
        strategy = matcher
        break;
    
    if strategy
      strategy.import source, (error, json) ->
        if error then options.error(error)
        else
          files = {}
          _.each json.files, (file) -> files[file.filename] =
            filename: file.filename
            content: file.content
            
          json.index ||= do ->
            filenames = _.keys(json.files)
      
            if "index.html" in filenames then "index.html"
            else
              html = _.filter filenames, (filename) -> /.html?$/.test(filename)
      
              if html.length then html[0]
              else filenames[0]
          
          options.plunk.set
            description: json.description
            files: files
          
          console.log "Plunk", options.success, options.plunk
          
          options.plunk.save({}, options)
          
          options.success(options.plunk)
          
          #coll = new plunker.PlunkCollection
          #coll.create _.defaults(json, options.defaults), options
    else
      options.error("Import error", "The source you provided is not a recognized source.")
    @

)(@plunker ||= {})