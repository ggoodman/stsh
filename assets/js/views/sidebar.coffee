((exports) ->

  class exports.Sidebar extends Backbone.View
    template: Handlebars.compile """
      <h2 class="header">Files</h2>
      <ul class="files">
        {{#each buffers}}
          if filename == active
          <li>{{filename}}</li>
        {{/each}}
      </ul>
    """
    
    initialize: ->
      @render()
      
      render = _.throttle(@render, 100)
      
      @model.on "change", render
      @model.buffers.on "add remove reset", render
      
    render: =>
      @$el.html $(@template(@model.toJSON()))
      @

)(window)