express = require("express")
gzippo = require("gzippo")
resource = require("express-resource")
_ = require("underscore")._
Gisty = require("gisty")

config = _.defaults require("./config"),
  store: "memory"
  ttl: 60 * 60 * 24 * 2 # 2 days
  server: ""

app = module.exports = express.createServer()
  
app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"
  app.set "view options", layout: false
  
  app.use express.logger()
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.compiler
    src: "#{__dirname}/assets"
    dest: "#{__dirname}/public"
    enable: ["coffeescript"]
  app.use gzippo.staticGzip("#{__dirname}/public")
  app.use gzippo.compress()

{Store} = require("./lib/stores/#{config.store}")
store = new Store(config)

app.all "/api/*", (req, res, next) ->
  res.header("Access-Control-Allow-Origin", "*")
  
  #if req.method == "OPTIONS"
  res.header("Access-Control-Allow-Headers", req.header("Access-Control-Request-Headers")) # I hear an echo. Do you?
  res.header("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE")
  res.header("Access-Control-Max-Age", 60 * 60 * 24 * 2) # 2 days
  
    #return res.send() if req.method == "OPTIONS"
  
  next()
  
# Expose the public api for plunks
app.resource "api/v1/plunks", require("./api/plunks")(store)


app.get "/", (req, res, next) ->
  res.render("index")



plunks = require("./lib/plunks")(store)
gists = {}

app.get "/gist/:id", (req, res, next) ->
  return res.redirect(gists[req.params.id]) if gists[req.params.id]
  
  gisty = new Gisty
  gisty.fetch req.params.id, (err, gist) ->
    return res.render("error/gist", {id: req.params.id, error: err}) if err
    
    files = {}
    _.map gist.files, (file, filename) ->
      files[filename] = 
        content: file.content
        mime: file.type
    
    json =
      description: gist.description
      files: files
      
    if req.query.index then json.index = req.query.index
    
    plunks.create json, (err, plunk) ->
      return next(err) if err
      
      gists[gist.id] = plunk.url
      
      res.redirect(plunk.url)

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
  body = _.extend({}, err)
  if err.message then body.message = err.message
  if err.errors then body.errors = err.errors
  if err.stack then body.stack = err.stack
  
  res.json body, err.number or 400
