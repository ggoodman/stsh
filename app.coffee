express = require("express")
resource = require("express-resource")
_ = require("underscore")._

config = _.defaults require("./config"),
  store: "memory"
  ttl: 60 * 60 * 24 * 2 # 2 days

app = module.exports = express.createServer()
  
app.configure ->
  app.use express.logger()
  app.use express.methodOverride()
  app.use express.bodyParser()
  

{Store} = require("./lib/stores/#{config.store}")
store = new Store(config)

# Expose the public api for plunks
app.resource "api/v1/plunks", require("./api/plunks")(store)
    

# Serve up a plunk
app.get "/:id/", (req, res, next) ->
  store.fetch req.params.id, (err, plunk) ->
    return res.send(500) if err
    return res.send(404) unless plunk 
    
    file = plunk.files[plunk.index]
    
    return res.send(404) unless file
    return res.send(file.content, {"Content-Type": file.mime})
app.get "/:id", (req, res) -> res.redirect("/#{req.params.id}/", 301)

# Serve a specific file in a plunk
app.get "/:id/*", (req, res, next) ->
  store.fetch req.params.id, (err, plunk) ->
    return res.send(500) if err
    return res.send(404) unless plunk 
    
    file = plunk.files[req.params[0]]
    
    return res.send(404) unless file
    return res.send(file.content, {"Content-Type": file.mime})

app.error (err, req, res, next) ->
  body = {}
  if err.message then body.message = err.message
  if err.errors then body.errors = err.errors
  
  res.json body, err.number or 400
