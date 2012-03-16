((plunker) ->
  plunker.themes = {}

  # Async mode loader
  plunker.themes.load = (name, cb) ->
    if plunker.themes[name] then cb(plunker.themes[name])
    else  
      $script "/js/ace/theme-#{name}.js", "theme-#{name}"
      $script.ready "theme-#{name}", ->
        cb (plunker.themes[name] = require("ace/theme/#{name}"))
          
)(@plunker ||= {})