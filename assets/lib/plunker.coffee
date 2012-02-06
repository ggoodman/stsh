
addThumbnail = (plunk) ->
  $li = $("<li></li>").addClass("span3").addClass("plunk")
  $a = $("<a></a>").attr("href", plunk.url).addClass("thumbnail").appendTo($li)
  $img = $("<img />")
    .attr("src", "http://placehold.it/205x154&text=Loading...")
    .attr("data-original", "http://immediatenet.com/t/l3?Size=1024x768&URL=#{plunk.url}")
    .attr("alt", plunk.description or "Plunk: #{plunk.id}")
    .addClass("lazy")
    .appendTo($a)
  $caption = $("<div></div>")
    .addClass("caption")
    .appendTo($a)
  $title = $("<h5>Plunk: #{plunk.id}</h5>")
    .addClass("title")
    .appendTo($caption)
  $desc = $("<p>#{plunk.description or 'Untitled'}</p>")
    .attr("title", plunk.description or "Untitled")
    .addClass("description")
    .appendTo($caption)

  $a.on "click", ->
    showPreview(plunk)
    false
  
  $li.appendTo("#recent")
  
showPreview = (plunk) ->
  $modal = $("<div></div>").addClass("modal")
  $header = $("<div><a class=\"close\" data-dismiss=\"modal\">×</a><h3>#{plunk.description or 'Untitled'}</h3></div>")
    .addClass("modal-header")
    .appendTo($modal)
  $body = $("<div></div>")
    .addClass("modal-body")
    .appendTo($modal)
  $iframe = $("<iframe></iframe>")
    .attr("src", plunk.url)
    .addClass("preview")
    .appendTo($body)
  $footer = $("<div></div>")
    .addClass("modal-footer")
    .appendTo($modal)
  $launch = $("<a><i class=\"icon-resize-full icon-white\"></i> Fullscreen</a>")
    .attr("href", plunk.url)
    .addClass("btn")
    .addClass("btn-primary")
    .appendTo($footer)
  
  $modal.modal().modal("show").on "hidden", ->
    $modal.remove()

# Return Promise
loadGist = (id) ->
  jQuery.ajax "https://api.github.com/gists/#{id}",
    dataType: "jsonp"

# Return Promise
createPlunk = (json) ->
  jQuery.ajax "http://plunker.no.de/api/v1/plunks",
    type: "post",
    dataType: "json"
    contentType: "application/json"
    data: JSON.stringify(json)

$ ->
  $("form.gist-import").on "submit", ->
    loadGist($("input.gist").val()).done (gist) ->
      gist = gist.data
      json =
        description: gist.description or ""
        files: {}
      
      json.files[filename] = file.content for filename, file of gist.files
      
      createPlunk(json).done (data) ->
        showPreview(data)
        addThumbnail(data)
      
    false
    
  
  jQuery.ajax "//#{location.hostname}/api/v1/plunks",
    dataType: "json"
    cache: false
    success: (json) ->
      for plunk in json then do (plunk) ->
        addThumbnail(plunk)
      
      $("img.lazy").lazyload
        threshold: 200
        effect: "fadeIn"
  