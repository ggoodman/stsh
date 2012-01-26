express = require("express")
config = require("./config")

app = module.exports = express.createServer()
  
app.configure ->
  app.use express.logger()
  app.use express.methodOverride()
  app.use express.bodyParser()


{Store} = require("./lib/stores/redis")
{Plunks, Plunk} = require("./lib/plunks")

store = new Store(config.redis)

Plunk::sync = store.sync
Plunks::sync = store.sync

plunks = new Plunks


app.post "/api/v1/plunks", (req, res) ->
  plunks.create req.body,
    success: (model) -> res.json model.toJSON()
    error: (model, err) -> res.send err, 400

app.get "/api/v1/plunks/:id", (req, res) ->
  plunk = new Plunk(id: req.param("id"))
  plunk.fetch
    success: (model) -> res.json model.toJSON()
    error: (model, err) -> res.send err, 400




app.get "/:id/", (req, res) ->
  plunk = new Plunk(id: req.param("id"))
  plunk.fetch
    success: (model) ->
      filename = model.get("index")
      file = model.files.get(filename)
      
      if file then res.send file.get("content"), { "Content-Type": file.get("mime") }
      else res.send "#{filename} not found in plunk", 404
    error: (err) ->
      res.send "No such plunk", 404

app.get "/:id", (req, res) ->
  res.redirect(req.url + "/", 301)

app.get "/:id/:filename", (req, res) ->
  plunk = new Plunk(id: req.param("id"))
  plunk.fetch
    success: (model) ->
      filename = req.param("filename")
      file = model.files.get(req.param("filename"))
      
      if file then res.send file.get("content"), { "Content-Type": file.get("mime") }
      else res.send "#{filename} not found in plunk", 404
    error: (err) ->
      res.send "No such plunk", 404


      
app.get "/", (req, res) ->
  res.send "Welcome to Plunk"