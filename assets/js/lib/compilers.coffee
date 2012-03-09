(@plunker ||= {}).compilers =
  coffee: (code, cb) ->
    $script "/js/compilers/coffee-script.js", "compiler-coffee"
    $script.ready "compiler-coffee", ->
      try
        compiled = CoffeeScript.compile(code, bare: true)
        return cb null,
          type: "code"
          body: compiled
          lang: "javascript"
      catch error
        return cb error
    return
    
  markdown: (code, cb) ->
    $script "/js/compilers/showdown.js", "compiler-showdown"
    $script.ready "compiler-showdown", ->
      converter = new Showdown.converter()
      try
        compiled = converter.makeHtml(code)
        return cb null,
          type: "html"
          body: compiled
      catch error
        return cb error
      return  