((plunker) ->

  plunker.import = (source, options = {}) ->
    self = @
    
    options = _.defaults options,
      wait: true
      silent: false
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
          json.index ||= do ->
            filenames = _.keys(json.files)
      
            if "index.html" in filenames then "index.html"
            else
              html = _.filter filenames, (filename) -> /.html?$/.test(filename)
      
              if html.length then html[0]
              else filenames[0]
          options.success(json)
    else
      options.error("Import error", "The source you provided is not a recognized source.")
    @

)(@plunker ||= {})