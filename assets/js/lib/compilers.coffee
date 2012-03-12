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
          title: "Compiled coffee-script"
      catch error
        return cb error
    return
    
  markdown: (code, cb) ->
    $script "/js/compilers/showdown.js", "compiler-markdown"
    $script.ready "compiler-markdown", ->
      converter = new Showdown.converter()
      try
        compiled = converter.makeHtml(code)
        return cb null,
          type: "html"
          body: compiled
          title: "Rendered markdown"
      catch error
        return cb error
      return
    
  javascript: (code, cb) ->
    $script "/js/compilers/jshint.js", "compiler-jshint"
    $script.ready "compiler-jshint", ->
      try
        valid = JSHINT code,
          browser: false
          devel: true
        
        if valid
          $script "/js/compilers/beautify.js", "compiler-javascript"
          $script.ready "compiler-javascript", ->
            compiled = js_beautify code,
              indent_size: 2
              intent_char: " "
            return cb null,
              type: "code"
              body: compiled
              lang: "javascript"
              title: "Beautified js"
        else
          $wrap = $("<div></div>")
          $report = $("<div><h4>Errors:</h4></div>")
            .addClass("jshint-report")
            .addClass("alert")
            .addClass("alert-block")
            .addClass("alert-error")
            .appendTo($wrap)
          $errors = $("<ul></ul>").addClass("jshint-errors").appendTo($report)
        
          _.each JSHINT.errors, ({line, reason, evidence, character}) ->
            $li = $("<li></li>").appendTo($errors)
            $error = $("<p></p>").appendTo($li)
            $line = $("<a>Line #{line}</a>")
              .attr("href", "javascript:void(0)")
              .attr("data-line", line)
              .attr("data-char", character)
              .addClass("lineno")
              .appendTo($error)
            $error.append(":&nbsp;")
            $code = $("<code>#{evidence}</code>").appendTo($error)
            $reason = $("<p>#{reason}</p>").appendTo($li)
          
          html = $wrap.html()
          $wrap.remove()

          return cb null,
            type: "html"
            body: html
            title: "jsLint"
            
      catch error
        return cb error
      return
   
  html: (code, cb) ->
    $script "/js/compilers/beautify-html.js", "compiler-html"
    $script "/js/compilers/beautify.js", "compiler-javascript"
    $script "/js/compilers/beautify-css.js", "compiler-css"
    $script.ready ["compiler-html", "compiler-javascript", "compiler-css"], ->
      try
        compiled = style_html code,
          indent_size: 2
          intent_char: " "
        return cb null,
          type: "code"
          body: compiled
          lang: "html"
          title: "Beautified html"
      catch error
        return cb error
      return
      
  css: (code, cb) ->
    $script "/js/compilers/beautify-css.js", "compiler-css"
    $script.ready "compiler-css", ->
      try
        compiled = css_beautify code,
          indent_size: 2
          intent_char: " "
        return cb null,
          type: "code"
          body: compiled
          lang: "css"
          title: "Beautified css"
      catch error
        return cb error
      return