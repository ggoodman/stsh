((plunker) ->
  class plunker.Card extends Backbone.View
    initialize: ->
      @model.on "change", @render
      @model.on "sync", @flash("Updated")
      @model.on "error", @flash("Error", "warning")
    
    events:
      "click .delete": "handleDelete"
      "click .refresh": "handleRefresh"
    
    tagName: "li"
    className: "span3 plunk"

    template: """
      <div class="thumbnail">
        <h5 class="description" title="{{description}}">{{description}}</h5>
        <a href="{{html_url}}">
          <img src="http://placehold.it/205x154&text=Loading..." data-original="http://immediatenet.com/t/l3?Size=1024x768&URL={{raw_url}}?_={{dateToTimestamp updated_at created_at}}" class="lazy" />
        </a>
        <div class="caption">
          <p>
            {{#if author}}
              by&nbsp;<a href="{{author.url}}" target="_blank">{{author.name}}</a>
            {{else}}
              by&nbsp;Anonymous
            {{/if}}
            <abbr class="timeago created_at" title="{{or updated_at created_at}}">{{dateToLocaleString updated_at created_at}}</abbr>
            {{#if source}}
              on&nbsp;<a href="{{source.url}}" target="_blank">{{source.name}}</a>
            {{/if}}
          </p>
        </div>
          <div class="operations">
            <div class="btn-toolbar">
              {{#if token}}
                <a class="btn btn-mini btn-primary edit" title="Edit in Plunker" href="/edit/{{id}}">
                  <i class="icon-pencil icon-white"></i>
                </a>
                {{#if source}}
                  <button class="btn btn-mini btn-success refresh" title="Refresh from source">
                    <i class="icon-refresh icon-white"></i>
                  </button>
                {{/if}}
                <button class="btn btn-mini btn-danger delete" title="Delete">
                  <i class="icon-trash icon-white"></i>
                </button>
              {{else}}
                <a class="btn btn-mini btn-primary edit" title="Fork and edit in Plunker" href="/edit/{{id}}">
                  <i class="icon-pencil icon-white"></i>
                </a>              
              {{/if}}
            </div>
          </div>
      </div>
    """
    
    render: =>
      compiled = Handlebars.compile(@template)
      @$el.html $(compiled(@model.toJSON()))
      @$(".timeago").timeago()
      @$("img.lazy").lazyload()
      @
    
    flash: (message, type = "success") =>
      self = @
      ->
        $tag = $("<span>#{message}</span>").addClass("label label-#{type}")
        self.$(".caption p").prepend($tag)
        
        setTimeout((-> $tag.fadeOut()), 3000)

    
    handleDelete: ->
      @model.destroy() if confirm "Are you sure that you would like to delete this plunk?"
    
    handleRefresh: ->
      unless @model.get("source")?.url then alert "Unable to refresh a plunk without a source" 
      else if confirm "Are you sure that you would like to refresh this plunk from its source?"
        self = @
        source = @model.get("source").url
        
        for name, matcher of plunker.importers
          if matcher.test(source)
            strategy = matcher
            break
        
        if strategy then strategy.import source, (error, json) ->
          if error then alert error
          else            
            # Remove fields that can not be updated
            delete json.source
            delete json.author
            
            
            self.model.set json # Need to break this into two operations.. thanks Backbone silent: true on wait: true saves
            unless _.isEmpty(self.model.changes)
              self.model.save {},
                wait: true
                silent: false
            else self.flash("No changes", "warning")()

  class Page extends Backbone.Model
  
  class Pager extends Backbone.View
    template: Handlebars.compile """
      {{#if prev}}
        <li class="previous">
          <a href="{{prev}}">&larr; Newer</a>
        </li>
      {{/if}}
      {{#if next}}
        <li class="next">
          <a href="{{next}}">Older &rarr;</a>
        </li>
      {{/if}}      
    """
    
    events:
      "click .next a":      -> @trigger "intent:next", arguments...
      "click .previous a":  -> @trigger "intent:prev", arguments...
    
    initialize: ->
      @model.on "change reset", @render
    
    render: =>
      @$el.html @template(@model.toJSON())
      @    

  class plunker.RecentPlunks extends Backbone.View
    initialize: ->
      self = @

      @size = 8
      @page = new Page
      @pager = new Pager
        el: document.getElementById("pager")
        model: @page
      
      @pager.on "intent:next intent:prev", (e) ->
        e.preventDefault()
        self.collection.url = $(e.target).attr("href")
        self.collection.fetch()
      
      @collection.parse = _.wrap @collection.parse, (parse, json, xhr) ->
        self.page.clear()
        
        if link = xhr.getResponseHeader("Link")
          page = {}
          
          link.replace /<([^>]+)>;\s*rel="(next|prev|first|last)"/gi, (match, href, rel) ->
            page[rel] = href
          
          self.page.set(page)

        parse(json)
      
      self.cards = {}
      @collection.on "reset", (coll) ->
        self.removeCard({id: id}, coll) for id, card of self.cards
        coll.chain().first(self.size).each (plunk, index) -> self.addCard(plunk, coll, index)
      @collection.on "add", (plunk, coll, options) -> self.addCard(plunk, coll, options.index)
      @collection.on "destroy remove", (plunk, coll, options) -> self.removeCard(plunk, coll)

    addCard: (plunk, coll, index) =>
      return unless plunk
      
      card = new plunker.Card(model: plunk)

      if index
        @$el.children().eq(index - 1).after(card.render().$el)
      else
        @$el.prepend card.render().$el

      @$el.children().slice(@size).remove()

      @cards[plunk.id] = card
      
    removeCard: (plunk, coll) =>
      self = @
      
      card = @cards[plunk.id]
      card.$el.fadeOut "slow", ->
        card.remove()
        self.addCard(self.collection.at(self.size - 1), self.collection, self.size - 1) if self.collection.length >= self.size
      delete @cards[plunk.id]

)(@plunker ||= {})