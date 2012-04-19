((plunker) ->

  class plunker.User extends Backbone.Model
    initialize: ->
      self = @
      
      plunker.mediator.on "event:auth", ->
        console.log "AUTH", arguments...
      
      plunker.mediator.on "intent:login", ->
        self.showLoginWindow() 
    
    
    showLoginWindow: (width = 1000, height = 650) ->
      screenHeight = screen.height
      left = Math.round((screen.width / 2) - (width / 2))
      top = 0
      if (screenHeight > height)
          top = Math.round((screenHeight / 2) - (height / 2))
      
      login = window.open "/auth/github", "Sign in with Github", """
        left=#{left},top=#{top},width=#{width},height=#{height},personalbar=0,toolbar=0,scrollbars=1,resizable=1
      """
      
      winCloseCheck = ->
        return if login && !login.closed
        clearInterval(winListener)

      winListener = setInterval(winCloseCheck, 1000)
      
      if login then login.focus();
      
    


)(@plunker or @plunker = {})