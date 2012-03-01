((exports) ->
  class exports.Card extends Backbone.View
    initialize: ->
      @model.on "change", @render
      @model.on "sync", @flash
    
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
              from&nbsp;<a href="{{source.url}}" target="_blank">{{source.name}}</a>
            {{else}}
              no source
            {{/if}}
          </p>
        </div>
        {{#if token}}
          <div class="operations">
            <div class="btn-toolbar">
              {{#if source}}
                <button class="btn btn-mini btn-success refresh" title="Refresh from source">
                  <i class="icon-refresh icon-white"></i>
                </button>
              {{/if}}
              <button class="btn btn-mini btn-danger delete" title="Delete">
                <i class="icon-trash icon-white"></i>
              </button>
            </div>
            <div class="edge"></div>
          </div>
        {{/if}}
      </div>
    """
    
    render: =>
      compiled = Handlebars.compile(@template)
      @$el.html $(compiled(@model.toJSON()))
      @$(".timeago").timeago()
      @$("img.lazy").lazyload()
      @
    
    flash: =>
      @$(".thumbnail").animate {"background-color": "#f5e5e5"},
        duration: "fast"
        queue: true
      @$(".thumbnail").animate {"background-color": "#ffffff"},
        duration: "slow"
        queue: true
    
    handleDelete: ->
      @model.destroy() if confirm "Are you sure that you would like to delete this plunk?"
    
    handleRefresh: ->
      unless @model.get("source")?.url then alert "Unable to refresh a plunk without a source" 
      else if confirm "Are you sure that you would like to refresh this plunk from its source?"
        self = @
        source = @model.get("source").url
        
        for matcher in plunkSources
          if strategy = matcher(source) then break
        
        if strategy then strategy source, (error, json) ->
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
                #success: -> alert "SUCCESS"
                #error: -> alert "FAIL"        
          

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
      card = @cards[plunk.id]
      card.$el.fadeOut "slow", -> card.remove()
      delete @cards[plunk.id]

)(window)