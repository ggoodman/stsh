((exports) ->

  class exports.Toolbar extends Backbone.View
    template: Handlebars.compile """
      <div class="btn-toolbar pull-right">
        <div class="btn-group">
          <a class="btn btn-inverse new" href="/edit">
            <i class="icon-file icon-white" />
            New plunk
          </a>
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
        <div class="btn-group">
          <button class="btn btn-success refresh">
            <i class="icon-refresh icon-white" />
            Refresh
          </button>
        </div>
      </div>
    """

    events:
      "click .refresh": (e) -> plunker.trigger "intent:refresh"
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