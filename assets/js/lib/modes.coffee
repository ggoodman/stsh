((plunker) ->
  plunker.modes =
    c_cpp:
      title: "C/C++"
      extensions: ["c", "cpp", "cxx", "h", "hpp"]
    clojure:
      title: "Clojure"
      extensions: ["clj"]
    coffee:
      title: "CoffeeScript"
      extensions: ["coffee"]
    coldfusion:
      title: "ColdFusion"
      extensions: ["cfm"]
    csharp:
      title: "C#"
      extensions: ["cs"]
    css:
      title: "CSS"
      extensions: ["css"]
    groovy:
      title: "Groovy"
      extensions: ["groovy"]
    haxe:
      title: "haXe"
      extensions: ["hx"]
    html:
      title: "HTML"
      extensions: ["html", "htm"]
    java:
      title: "Java"
      extensions: ["java"]
    javascript:
      title: "JavaScript"
      extensions: ["js"]
    json:
      title: "JSON"
      extensions: ["json"]
    latex:
      title: "LaTeX"
      extensions: ["tex"]
    lua:
      title: "Lua"
      extensions: ["lua"]
    markdown:
      title: "Markdown"
      extensions: ["md", "markdown"]
    ocaml:
      title: "OCaml"
      extensions: ["ml", "mli"]
    perl:
      title: "Perl"
      extensions: ["pl", "pm"]
    pgsql:
      title: "pgSQL"
      extensions: ["pgsql", "sql"]
    php:
      title: "PHP"
      extensions: ["php"]
    powershell:
      title: "Powershell"
      extensions: ["ps1"]
    python:
      title: "Python"
      extensions: ["py"]
    scala:
      title: "Scala"
      extensions: ["scala"]
    scss:
      title: "SCSS"
      extensions: ["scss"]
    ruby:
      title: "Ruby"
      extensions: ["rb"]
    sql:
      title: "SQL"
      extensions: ["sql"]
    svg:
      title: "SVG"
      extensions: ["svg"]
    textile:
      title: "Textile"
      extensions: ["textile"]
    xml:
      title: "XML"
      extensions: ["xml"]

  # Build the regex's to match the modes also, put the name back in
  _.each plunker.modes, (value, key) ->
    plunker.modes[key] = _.defaults value,
      name: key
      regex: new RegExp("\\.(" + value.extensions.join("|") + ")$", "i")
  
  # Async mode loader
  plunker.modes.load = (mode, cb) ->
    if mode.mode then return cb(mode)
    else if mode.name
      $script "/js/ace/mode-#{mode.name}.js", "mode-#{mode.name}"
      $script.ready "mode-#{mode.name}", ->
        Mode = require("ace/mode/#{mode.name}").Mode
        mode.mode ||= new Mode
        cb(mode)
  
  # Helper to load a mode by name
  plunker.modes.loadByName = (name, cb) ->
    mode = plunker.modes[name]
    
    if mode then plunker.modes.load(mode, cb)
    else cb()
  
  # Helper to determine and load a mode by filename
  plunker.modes.loadByFilename = (filename, cb) ->
    mode = _.find plunker.modes, (mode) -> filename.match(mode.regex)
    
    if mode then plunker.modes.load(mode, cb)
    else cb()
          
)(@plunker ||= {})