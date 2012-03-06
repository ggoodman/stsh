((exports) ->
  class exports.Card extends Backbone.View
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
          <img src="http://placehold.it/205x154&text=Loading..." data-original="http://immediatenet.com/t/l3?Size=1024x768&URL={{raw_url}}" class="lazy" />
        </a>
        <div class="caption">
          <p>
            {{#if author}}
              by&nbsp;<a href="{{author.url}}" target="_blank">{{author.name}}</a>
            {{else}}
              by&nbsp;Anonymous
            {{/if}}
            <abbr class="timeago created_at" title="{{created_at}}">{{dateToLocaleString created_at}}</abbr>
            {{#if source}}
              on&nbsp;<a href="{{source.url}}" target="_blank">{{source.name}}</a>
            {{/if}}
          </p>
        </div>
          <div class="operations">
            <div class="btn-toolbar">
              <a class="btn btn-mini btn-primary edit" title="Edit in Plunker" href="/edit/{{id}}">
                <i class="icon-pencil icon-white"></i>
              </a>
              {{#if token}}
                {{#if source}}
                  <button class="btn btn-mini btn-success refresh" title="Refresh from source">
                    <i class="icon-refresh icon-white"></i>
                  </button>
                {{/if}}
                <button class="btn btn-mini btn-danger delete" title="Delete">
                  <i class="icon-trash icon-white"></i>
                </button>
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
          

  class exports.RecentPlunks extends Backbone.View
    initialize: ->
      self = @
      self.cards = {}
      @collection.on "reset", (coll) ->
        card.remove() for card in self.cards
        coll.chain().first(8).each (plunk, index) -> self.addCard(plunk, coll, index)
      @collection.on "add", (plunk, coll, options) -> self.addCard(plunk, coll, options.index)
      @collection.on "destroy", (plunk, coll, options) -> self.removeCard(plunk, coll)

    addCard: (plunk, coll, index) =>
      card = new Card(model: plunk)

      if index
        @$el.children().eq(index - 1).after(card.render().$el)
      else
        @$el.prepend card.render().$el

      @$el.children().slice(8).remove()

      @cards[plunk.id] = card
      
    removeCard: (plunk, coll) =>
      self = @
      
      card = @cards[plunk.id]
      card.$el.fadeOut "slow", ->
        card.remove()
        self.addCard(self.collection.at(7), self.collection, 7) if self.collection.length >= 7
      delete @cards[plunk.id]

)(window)