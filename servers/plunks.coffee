express = require("express")
_ = require("underscore")._

app = module.exports = express.createServer()

config = _.defaults require("../config"),
  store: "memory"
  ttl: 60 * 60 * 24 * 2 # 2 days


app.configure ->
  app.use require("../lib/plunker").middleware(config)

  app.use express.logger()
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })



app.param "plunk", (req, res, next, id) ->
  req.plunker.read id, (err, plunk) ->
    if err then next(err)
    else
      req.plunk = plunk
      next()

# Serve up a plunk
app.get "/:plunk/", (req, res, next) ->
  return res.send(404) unless plunk = req.plunk

  file = plunk.files[plunk.index]

  return res.send(404) unless file
  return res.send(file.content, {"Content-Type": file.mime})
app.get "/:id", (req, res) -> res.redirect("/#{req.params.id}/", 301)

# Serve a specific file in a plunk
app.get "/:plunk/*", (req, res, next) ->
  return res.send(404) unless plunk = req.plunk

  file = plunk.files[req.params[0]]

  return res.send(404) unless file
  return res.send(file.content, {"Content-Type": file.mime})


if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Plunks app listening on port %d", process.env.PORT || 8080