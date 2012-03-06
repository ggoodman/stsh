githubRegex = /^(?:(?:https?\:\/\/)?gist\.github\.com\/)?([0-9a-z]+)(?:#.+)?$/


((plunker) ->
  plunker.importers ?= {}
  plunker.importers.github = 
    test: (source) -> githubRegex.test(source)
    import: (source, callback) ->
      if matches = source.match(githubRegex)
        promise = $.ajax "https://api.github.com/gists/#{matches[1]}",
          timeout: 8000
          dataType: "jsonp"
          error: -> callback("Import failed")
          success: (data) ->
            if data.meta.status >= 400 then callback("Import failed")
            else
              gist = data.data
      
              json =
                description: gist.description
                source:
                  name: "Github"
                  url: gist.html_url
                files: {}
      
              if gist.user then json.author =
                name: gist.user.login
                url: "https://github.com/#{gist.user.login}"
              
              for filename, file of gist.files
                json.files[filename] =
                  filename: filename
                  content: file.content 
                  mime: file.type
              
              callback(null, json)
      else callback("Impossible error")
)(plunker ?= {})