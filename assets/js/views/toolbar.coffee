((exports) ->

  class exports.Toolbar extends Backbone.View
    template: Handlebars.compile """
      <div class="btn-toolbar pull-right">
        <div class="btn-group">
          <a class="btn btn-success new" href="/edit">
            <i class="icon-file icon-white" />
            Create
          </a>
          <a class="btn btn-success dropdown-toggle" data-toggle="dropdown" href="javascript:void(0)">
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu">
            <li>
              <a href="/edit/from:1961272">Base html5 page</a>
            </li>
            <li>
              <a href="/edit/from:1986619">Base + jQuery</a>
            </li>
          </ul>
        </div>
        <div class="btn-group">
          <button class="btn btn-primary save">
            <i class="icon-share icon-white" />
            Save
          </button>
        </div>        <div class="btn-group">
          <button class="btn btn-info refresh">
            <i class="icon-refresh icon-white" />
            Refresh
          </button>
        </div>

        <div class="btn-group">
          <select class="input-medium view">
            <option value="sidebar editor preview">All panels</option>
            <option value="sidebar editor">Sidebar and editor</option>
            <option value="editor preview">Editor and preview</option>
            <option value="editor">Editor only</option>
            <option value="preview">Preview only</option>
          </select>
        </div>
      </div>
    """

    events:
      "click .refresh": (e) -> plunker.trigger "intent:refresh"
      "click .save": (e) -> plunker.trigger "intent:save"
      "change .view": (e) ->
        $("#content").removeClass("sidebar editor preview").addClass($(e.target).val())
        plunker.trigger "event:resize"
    
    initialize: ->
      @render()
      @$(".view").val($("#content").attr("class"))
      
    render: =>
      @$el.html $(@template())
      @

)(window)