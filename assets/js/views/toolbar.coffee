((exports) ->

  class exports.Toolbar extends Backbone.View
    template: Handlebars.compile """
      <div class="btn-toolbar">
        <div class="btn-group">
          <a class="btn btn-success new" href="/edit">
            <i class="icon-file icon-white" />
            New
          </a>
          <a class="btn btn-success dropdown-toggle" data-toggle="dropdown" href="javascript:void(0)">
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu">
            <li>
              <a href="/edit/from:1961272">Basic html</a>
            </li>
            <li>
              <a href="/edit/from:1986619">jQuery</a>
            </li>
            <li>
              <a href="/edit/from:1992850">jQuery + Coffee</a>
            </li>
            <li>
              <a href="/edit/from:1990582">YUI</a>
            </li>
          </ul>
        </div>
        <div class="btn-group">
          <button class="btn btn-primary save">
            <i class="icon-share icon-white" />
            Save
          </button>
        </div>
        <div class="btn-group">
          <button class="btn btn-danger save" disabled>
            <i class="icon-trash icon-white" />
            Delete
          </button>
        </div>
      </div>
      <div class="btn-toolbar">
        <div class="btn-group">
          <button class="btn btn-info run" data-toggle="button">
            <span class="run-start">
              <i class="icon-play icon-white" />
              Run
            </span>
            <span class="run-stop">
              <i class="icon-stop icon-white" />
              Stop
            </span>
          </button>
        </div>
      </div>
      <div class="btn-toolbar">
        <div class="btn-group" data-toggle="buttons-radio">
          <button class="btn edit-only active live-off" title="No live preview">
            <i class="icon-off" />
          </button>
          <button class="btn edit-only live-compile" title="Live code compilation and preview">
            <i class="icon-list" />
          </button>
          <button class="btn edit-only live-preview" title="Live preview">
            <i class="icon-eye-open" />
          </button>
        </div>
      </div>
    """

    events:
      "click .run.active": (e) -> plunker.trigger "intent:preview-disable"
      "click .run:not(.active)": (e) -> plunker.trigger "intent:preview-enable"
      "click .save": (e) -> plunker.trigger "intent:save"
      "click .live-off": (e) -> plunker.trigger "intent:live-off"
      "click .live-compile": (e) -> plunker.trigger "intent:live-compile"
      "click .live-preview": (e) -> plunker.trigger "intent:live-preview"
    
    initialize: ->
      @render()
      @$(".view").val($("#content").attr("class"))
      
    render: =>
      @$el.html @template()
      @

)(window)