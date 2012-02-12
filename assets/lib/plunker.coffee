
addThumbnail = (plunk) ->
  $li = $("<li></li>").addClass("span3").addClass("plunk")
  $div = $("<div></div>").addClass("thumbnail").appendTo($li)
  $a = $("<a></a>").attr("href", plunk.url).appendTo($div)
  $img = $("<img />")
    .attr("src", "http://placehold.it/205x154&text=Loading...")
    .attr("data-original", "http://immediatenet.com/t/l3?Size=1024x768&URL=#{plunk.url}")
    .attr("alt", plunk.description or "Plunk: #{plunk.id}")
    .addClass("lazy")
    .appendTo($a)
  $caption = $("<div></div>")
    .addClass("caption")
    .appendTo($div)
  $description = $("<h5></h5>")
    .text("#{plunk.description or 'Untitled'}")
    .attr("title", plunk.description or "Untitled")
    .addClass("description")
    .appendTo($caption)
  
  $about = $("<p>by&nbsp;</p>")
    .addClass("about")
    .appendTo($caption)
  
  if plunk.author
    $author = $("<a></a>")
      .text(plunk.author.name)
      .attr("href", plunk.author.url)
      .attr("target", "_blank")
  else
    $author = $("<span>Anonymous</span>")
  
  $author.addClass("creator").appendTo($about)
  $about.append(" ")
  
  $when = $("<abbr>#{new Cromag(plunk.created_at).toLocaleString()}</abbr>")
    .addClass("timeago")
    .addClass("created_at")
    .attr("title", plunk.created_at)
    .appendTo($about)
    .timeago()
  
  $about.append("<br />")
  
  if plunk.source
    $about.append("from ")
    $source = $("<a>#{plunk.source.name}</a>")
      .addClass("source")
      .attr("href", plunk.source.url)
      .attr("target", "_blank")
      .appendTo($about)

  $a.on "click", ->
    showPreview(plunk)
    false
  
  $li.prependTo("#recent")
  
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
  jQuery.ajax "//#{location.hostname}/api/v1/plunks",
    type: "post",
    dataType: "json"
    contentType: "application/json"
    data: JSON.stringify(json)

showMessage = (title, message, additionalClass) ->
  $msg = $("<div></div>").addClass("alert alert-block fade in")
  $msg.addClass(additionalClass) if additionalClass?
  $close = $("<a>×</a>")
    .addClass("close")
    .attr("href", "#")
    .attr("data-dismiss", "alert")
    .appendTo($msg)
  $title = $("<h4>#{title}</h4>")
    .addClass("alert-heading")
    .appendTo($msg)
  $body = $("<p>#{message}</p>").appendTo($msg)
  
  $msg.insertAfter("form.gist-import")

showError = (xhr, err) ->
  showMessage("Import failed", err.toString(), "alert-error")
  $("form.gist-import input, form.gist-import button").prop("disabled", false)

  
$ ->
  $("form.gist-import").on "submit", ->
    $("form.gist-import input, form.gist-import button").prop("disabled", true)
    loadGist($("input.gist").val()).fail(showError).done (gist) ->
      gist = gist.data
      json =
        description: gist.description or ""
        source:
          name: "gist: #{gist.id}"
          url: gist.html_url
        author:
          name: gist.user.login
          url: "https://github.com/#{gist.user.login}"
          avatar_url: gist.user.avatar_url
        files: {}
      
      json.files[filename] = file.content for filename, file of gist.files
      
      createPlunk(json).fail(showError).done (data) ->
        showPreview(data)
        addThumbnail(data)
        showMessage("Import successful", "The gist was successfully imported into Plunker", "alert-success")
        $("form.gist-import input").val("").prop("disabled", false)
        $("form.gist-import button").prop("disabled", false)
      
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
  