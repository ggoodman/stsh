((exports) ->

  class exports.Toolbar extends Backbone.View
    template: Handlebars.compile """
      <button class="btn">Preview</button>
    """
    
    initialize: ->
      @render()
      
    render: =>
      @$el.html $(@template())
      @

)(window)