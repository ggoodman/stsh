((plunker) ->
  
  class plunker.Toolbar extends Backbone.View
    template: Handlebars.compile """
      <div class="btn-toolbar streamer">
        <div class="stream-disable status">
          <div class="input-prepend input-append">
            <span class="add-on" title="Streaming active"><i class="icon-random" /></span><input class="stream-id input-medium" type="text" value="{{stream}}" disabled /><button class="add-on btn stop" title="Disconnect from collaborative editing">
              <i class="icon-stop" />
            </button>
          </div>
        </div>
        <div class="btn-group stream-enable">
          <button class="btn start" data-toggle="dropdown">
            <i class="icon-random" />
            <span class="text">Stream</span>
          </button>
        </div>
      </div>
      <div class="btn-toolbar">
        <div class="btn-group group-new">
          <a class="btn btn-success new" href="/edit">
            <i class="icon-file icon-white" />
            <span class="text" title="Create a new, blank plunk">New</span>
          </a>
          <button class="btn btn-success dropdown-toggle" data-toggle="dropdown">
            <span class="caret"></span>
          </button>
          <ul class="dropdown-menu templates">
            <li>
              <a href="/edit/from:2312729">Basic html</a>
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
              <a href="/edit/from:2016721">Bootstrap</a>
            </li>
            <li>
              <a href="/edit/from:2016721">Bootstrap + Coffee</a>
            </li>
            <li class="divider"></li>
            <li>
              <a href="/edit/from:2050713">Backbone.js</a>
            </li>
            <li>
              <a href="/edit/from:2050746">Backbone.js + Coffee</a>
            </li>
            <li class="divider"></li>
            <li>
              <a href="/edit/from:1990582">YUI</a>
            </li>
            <li class="divider"></li>
            <li>
              <a href="/edit/from:1961272">AngularJS</a>
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
          <button class="btn btn-info run">
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
        <div class="btn-group live">
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
      {{#if plunk.id}}
        <div class="btn-toolbar">
          <div class="btn-group">
            <a class="btn share" title="Share this plunk" href="#share" data-toggle="modal">
              <i class="icon-share" />
            </a>
          </div>
        </div>
      {{/if}}
    """

    events:
      "click .run.active": (e) -> plunker.mediator.trigger "intent:preview-disable"
      "click .run:not(.active)": (e) -> plunker.mediator.trigger "intent:preview-enable"
      "click .save": (e) -> plunker.mediator.trigger "intent:save"
      "click .delete": (e) -> plunker.mediator.trigger "intent:delete"
      "click .live-off": (e) -> plunker.mediator.trigger "intent:live-off"
      "click .live-compile": (e) -> plunker.mediator.trigger "intent:live-compile"
      "click .live-preview": (e) -> plunker.mediator.trigger "intent:live-preview"
      "click .stream-enable .start": (e) -> plunker.mediator.trigger "intent:stream-start"
      "click .stream-disable .stop": (e) -> plunker.mediator.trigger "intent:stream-stop"
      "click .templates a": (e) ->       
        e.preventDefault()
        plunker.controller.navigate $(e.target).attr("href"),
          trigger: true
      "click .new": (e) ->
        e.preventDefault()
        plunker.mediator.trigger "intent:reset"
      
    
    initialize: ->
      self = @
      
      @render()

      @model.plunk.on "change:token change:id", @render

      plunker.mediator.on "event:preview-enable", ->
        self.$(".run").addClass("active")
        self.$(".live button").prop("disabled", true)
      plunker.mediator.on "event:preview-disable", ->
        self.$(".run").removeClass("active")
        self.$(".live button").prop("disabled", false)
      plunker.mediator.on "event:live-off", -> self.$(".live button").removeClass("active").filter(".live-off").addClass("active")
      plunker.mediator.on "event:live-compile", -> self.$(".live button").removeClass("active").filter(".live-compile").addClass("active")
      plunker.mediator.on "event:live-preview", -> self.$(".live button").removeClass("active").filter(".live-preview").addClass("active")
      
      plunker.mediator.on "event:stream-join event:stream-start", (id) ->
        self.$el.addClass("streamed")
        self.stream = id
        self.$(".stream-id").val(id).attr("size", id.length)
      plunker.mediator.on "event:stream-stop", ->
        delete self.stream
        self.$el.removeClass("streamed")
      
      @render = _.throttle(@render, 500)


    render: =>
      @$el.html @template
        session: @model.toJSON()
        plunk: @model.plunk.toJSON()
        stream: @stream
      
      @$("input.stream-id").attr "size", @stream.length if @stream
        
      @$(".stream-enable button").popover
        placement: "bottom"
        title: "Streaming session"
        content: """
          <p class="label label-warning">Caution: Experimental feature</p>
          <p>Streaming allows you to collaborate with others in real-time on the
          same shared state, called a stream.</p>
          <p>A stream is independent of your current plunk and will not be
          affected by saving.</p>
        """
      @

)(@plunker ||= {})