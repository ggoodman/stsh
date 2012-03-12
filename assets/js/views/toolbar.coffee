((plunker) ->
  
  class plunker.Toolbar extends Backbone.View
    template: Handlebars.compile """
      <div class="btn-toolbar">
        <div class="btn-group">
          <a class="btn btn-success new" href="/edit">
            <i class="icon-file icon-white" />
            <span class="text">New</span>
          </a>
          <button class="btn btn-success dropdown-toggle" data-toggle="dropdown">
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu templates">
            <li>
              <a href="/edit/from:1961272">Basic html</a>
            </li>
            <li class="divider"></li>
            <li>
              <a href="/edit/from:1986619">jQuery</a>
            </li>
            <li>
              <a href="/edit/from:2006604">jQuery + jQuery UI</a>
            </li>
            <li>
              <a href="/edit/from:1992850">jQuery + Coffee</a>
            </li>
            <li class="divider"></li>
            <li>
              <a href="/edit/from:1990582">YUI</a>
            </li>
          </ul>
        </div>
        <div class="btn-group">
          <button class="btn btn-primary save">
            <i class="icon-share icon-white" />
            <span class="text">Save</span>
          </button>
        </div>
        {{#if plunk.token}}
          <div class="btn-group">
            <button class="btn btn-danger delete">
              <i class="icon-trash icon-white" />
              <span class="text">Delete</span>
            </button>
          </div>
        {{/if}}
      </div>
      <div class="btn-toolbar">
        <div class="btn-group">
          <button class="btn btn-info run" data-toggle="button">
            <span class="run-start">
              <i class="icon-play icon-white" />
              <span class="text">Run</span>
            </span>
            <span class="run-stop">
              <i class="icon-stop icon-white" />
              <span class="text">Stop</span>
            </span>
          </button>
        </div>
      </div>
      <div class="btn-toolbar">
        <div class="btn-group" data-toggle="buttons-radio">
          <button class="btn edit-only active live-off" title="Hide preview pane">
            <i class="icon-off" />
          </button>
          <button class="btn edit-only live-compile" title="Show live compilation pane">
            <i class="icon-list" />
          </button>
          <button class="btn edit-only live-preview" title="Show live preview pane">
            <i class="icon-eye-open" />
          </button>
        </div>
      </div>
    """

    events:
      "click .run.active": (e) -> plunker.mediator.trigger "intent:preview-disable"
      "click .run:not(.active)": (e) -> plunker.mediator.trigger "intent:preview-enable"
      "click .save": (e) -> plunker.mediator.trigger "intent:save"
      "click .delete": (e) -> plunker.mediator.trigger "intent:delete"
      "click .live-off": (e) -> plunker.mediator.trigger "intent:live-off"
      "click .live-compile": (e) -> plunker.mediator.trigger "intent:live-compile"
      "click .live-preview": (e) -> plunker.mediator.trigger "intent:live-preview"
      "click .templates a": (e) ->       
        e.preventDefault()
        plunker.controller.navigate $(e.target).attr("href"),
          trigger: true
      "click .new": (e) ->
        e.preventDefault()
        plunker.mediator.trigger "intent:reset"
      
    
    initialize: ->
      @render()
      
      @model.plunk.on "change:token", @render

    render: =>
      @$el.html @template
        session: @model.toJSON()
        plunk: @model.plunk.toJSON()
      @

)(@plunker ||= {})