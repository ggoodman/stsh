((exports) ->
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
                by <a href="{{author.url}}" target="_blank">{{author.name}}</a>
              {{else}}
                by Anonymous
              {{/if}}
              <abbr class="timeago created_at" title="{{created_at}}">{{dateToLocaleString created_at}}</abbr>
              <br>
              {{#if source}}
                from <a href="{{source.url}}" target="_blank">{{source.name}}</a>
              {{else}}
                no source
              {{/if}}
            </p>
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
      self.cards = {}
      @collection.on "reset", (coll) ->
        card.remove() for card in self.cards
        coll.chain().first(8).each (plunk, index) -> self.addCard(plunk, coll, index)
      @collection.on "add", (plunk, coll, options) -> self.addCard(plunk, coll, options.index)

    addCard: (plunk, coll, index) =>
      console.log "AddCard", arguments...
      card = new Card(model: plunk)

      if index
        @$el.children().eq(index - 1).after(card.render().$el)
      else
        @$el.prepend card.render().$el

      @$el.children().slice(8).remove()

      @cards[plunk.id] = card

)(window)