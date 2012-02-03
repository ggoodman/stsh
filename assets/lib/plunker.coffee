$ ->
  jQuery.getJSON "//#{location.hostname}/api/v1/plunks", (json) ->
    for plunk in json then do (plunk) ->
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
#      $actions = $("<p></p>")
#        .addClass("actions")
#        .appendTo($caption)
#      $launch = $("<a><i class=\"icon-resize-full icon-white\"></i> Launch</a>")
#        .attr("href", plunk.url)
#        .addClass("btn btn-primary launch")
#        .appendTo($actions)

      $a.on "click", ->
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
        $launch = $("<a><i class=\"icon-resize-full icon-white\"></i> Launch</a>")
          .attr("href", plunk.url)
          .addClass("btn")
          .addClass("btn-primary")
          .appendTo($footer)
        
        $modal.modal().modal("show").on "hidden", ->
          $modal.remove()
  
        false
      
      $li.appendTo("#recent")
    
    $("img.lazy").lazyload
      threshold: 200
      effect: "fadeIn"
  