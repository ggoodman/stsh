updateTitle = ->
  document.title = $('#plunk').contents().find("title").text()  
$ ->
  $iframe = $("#plunk")
  setInterval(updateTitle, 1000)
  
  events = ["errorupdate", "timeupdate"]
  
  for event in events
    $iframe[0]["on" + event] = ->
      console.log event, arguments...
      
  $iframe.load ->
    console.log "LOAD", arguments...