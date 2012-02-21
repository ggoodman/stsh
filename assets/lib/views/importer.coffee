((exports) ->

  messageTemplate = Handlebars.compile """
    <div class="alert fade in {{class}}">
      <a href="javascript:void(0)" class="close" data-dismiss="alert">×</a>
      <strong>{{title}}</strong> {{message}}
    </div>
  """

  showSuccess = (plunk, coll) ->
    console.log "showSuccess", arguments...
    $("#importer").after $ messageTemplate
      title: "Import successful"
      message: "The plunk was successfully imported and created."
      class: "alert-success"

  showError = (title, message) ->
    console.log "showError", arguments...

    $("#importer").after $ messageTemplate
      title: title
      message: message
      class: "alert-error"

  class exports.Importer extends Backbone.View
    events:
      "submit":     "doImport"
      "click .btn": "doImport"

    initialize: ->
      self = @

      @collection.on "import:start", -> self.$el.addClass("import").find(".progress .bar").css(width: "0%").animate(width: "100%", "6s")
      @collection.on "import:fail import:success", -> self.$el.removeClass("import").find(".progress .bar").stop().css(width: "0%")

      @collection.on "error", showError
      @collection.on "add", showSuccess

    doImport: (e) =>
      e.preventDefault()

      plunks.import @$("#importer-input").val()

      false

)(window)