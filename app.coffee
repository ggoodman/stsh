coffee = require("coffee-script")
express = require("express")
gzippo = require("gzippo")
assets = require("connect-assets")

app = module.exports = express.createServer()

app.configure ->
  app.set "views", "#{__dirname}/views"
  app.set "view engine", "jade"
  app.set "view options", layout: false

  app.use express.logger()
  app.use assets()
  app.use gzippo.staticGzip("#{__dirname}/public")
  app.use gzippo.compress()
  app.use express.static("#{__dirname}/public")
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })


app.get "/", (req, res) ->
  res.render("index", page: "/")

app.get "/documentation", (req, res) ->
  res.render("documentation", page: "/documentation")

app.get "/preview/:id", (req, res) ->
  res.render("preview", id: req.params.id)

app.use "/api", require("./servers/api")
app.use "/", require("./servers/plunks")


if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Listening on port %d", process.env.PORT || 8080