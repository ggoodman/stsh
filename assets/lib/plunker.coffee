jQuery.timeago.settings.strings.seconds = "seconds"

((exports) ->
  Handlebars.registerHelper "dateToLocaleString", (isoString) ->
    new Cromag(isoString).toLocaleString()
  
  exports.plunker = {}
  
  class exports.Plunk extends Backbone.Model
    defaults:
      description: "Untitled"
    initialize: ->

    toJSON: ->
      json = super()
      json.description ||= "Untitled"
      json
  
  class exports.PlunkCollection extends Backbone.Collection
    url: -> "/api/v1/plunks"
    model: Plunk
    comparator: (model) -> -new Cromag(model.get("created_at")).valueOf()
    sync: (method, model, options) ->
      params = _.extend {}, options,
        url: @url()
        dataType: "json"
        
      switch method
        #when "create"
        when "read"
          params.type = "get"

        #when "update"
        #when "delete"
      
      $.ajax(params)
  
  class exports.Card extends Backbone.View
    initialize: ->
      @on "change", @render
      
    template: """
      <li class="span3 plunk">
        <div class="thumbnail">
          <h5 class="description" title="{{description}}">{{description}}</h5>
          <a href="{{html_url}}">
            <img src="http://placehold.it/205x154&text=Loading..." data-original="http://immediatenet.com/t/l3?Size=1024x768&URL={{html_url}}" class="lazy" />
          </a>
          <div class="caption">
            <p>
              {{#if author}}
                by <a href="{{author.url}}">{{author.name}}</a>
              {{else}}
                by Anonymous
              {{/if}}
              
              <abbr class="timeago created_at" title="{{created_at}}">{{dateToLocaleString created_at}}</abbr>
          </div>
        </div>
      </li>
    """
    render: =>
      compiled = Handlebars.compile(@template)
      @setElement $(compiled(@model.toJSON()))
      @$(".timeago").timeago()
      @

  class exports.RecentPlunks extends Backbone.View
    initialize: ->
      self = @
      self.cards = []
      @collection.on "reset", (coll) ->
        card.remove() for card in self.cards
        coll.each (plunk) ->
          card = new Card(model: plunk)
          card.render().$el.appendTo(self.$el)
          self.cards.push(card)        
  
  $ ->
    plunks = new PlunkCollection()
    recent = new RecentPlunks
      collection: plunks
      el: document.getElementById("recent")
    
    plunks.fetch()
    
    console.log recent
  
)(window)

###
addcard = (plunk) ->
  $li = $("<li></li>").addClass("span3").addClass("plunk")
  $div = $("<div></div>").addClass("card").appendTo($li)
  $description = $("<h5></h5>")
    .text("#{plunk.description or 'Untitled'}")
    .attr("title", plunk.description or "Untitled")
    .addClass("description")
    .appendTo($div)
  $a = $("<a></a>")
    .attr("href", plunk.html_url)
    .appendTo($div)
  $img = $("<img />")
    .attr("src", "http://placehold.it/205x154&text=Loading...")
    .attr("data-original", "http://immediatenet.com/t/l3?Size=1024x768&URL=#{plunk.html_url}")
    .attr("alt", plunk.description or "Plunk: #{plunk.id}")
    .addClass("lazy")
    .appendTo($a)
  $caption = $("<div></div>")
    .addClass("caption")
    .appendTo($div)


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

  if plunk.token
    $li.addClass("authorized")

  $a.on "click", ->
    showPreview(plunk)
    false

  $("#recent>li").slice(11).remove()

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
    .attr("src", plunk.html_url)
    .addClass("preview")
    .appendTo($body)
  $footer = $("<div></div>")
    .addClass("modal-footer")
    .appendTo($modal)
  $launch = $("<a><i class=\"icon-resize-full icon-white\"></i> Fullscreen</a>")
    .attr("href", plunk.html_url)
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
  jQuery.ajax "/api/v1/plunks",
    type: "post",
    dataType: "json"
    contentType: "application/json"
    data: JSON.stringify(json)

showMessage = (title, message, additionalClass) ->
  $msg = $("<div></div>").addClass("alert fade in")
  $msg.addClass(additionalClass) if additionalClass?
  $close = $("<a>×</a>")
    .addClass("close")
    .attr("href", "javascript:void(0)")
    .attr("data-dismiss", "alert")
    .appendTo($msg)
  $title = $("<strong>#{title}: </strong>").appendTo($msg)
  $body = $("<span>#{message}</span>").appendTo($msg)

  $msg.insertAfter("form.gist-import")

showError = (xhr, err) ->
  showMessage("Import failed", err.toString(), "alert-error")
  $("form.gist-import input, form.gist-import button").prop("disabled", false)
  $("form.gist-import input").val("")

determineStrategy = (input) ->
  if matches = input.match(/^(?:(?:https?\:\/\/)?gist\.github\.com\/)?(\d+)(?:#.+)?$/)
    strategy = ->
      loadGist(matches[1])

  # Fall back to the gist loader
  unless strategy
    strategy = -> loadGist(input)

  return strategy

$ ->
  $("form.gist-import").on "submit", (e) ->
    e.preventDefault()

    strategy = determineStrategy($("input.gist").val())

    $("form.gist-import input, form.gist-import button").prop("disabled", true)
    strategy().fail(showError).done (data) ->
      if data.meta.status >= 400 then showError(null, data.data.message)
      else
        gist = data.data
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
          addcard(data)
          showMessage("Success", "A new plunk was born!", "alert-success")
          $("form.gist-import input").val("").prop("disabled", false)
          $("form.gist-import button").prop("disabled", false)

    false


  jQuery.ajax "/api/v1/plunks",
    dataType: "json"
    cache: false
    success: (json) ->
      for plunk in json then do (plunk) ->
        addcard(plunk)

      $("img.lazy").lazyload
        threshold: 200
        effect: "fadeIn"
###