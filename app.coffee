coffee = require("coffee-script")
express = require("express")
gzippo = require("gzippo")
assets = require("connect-assets")

app = module.exports = express.createServer()

app.use assets()
app.use gzippo.staticGzip("#{__dirname}/public")
#app.use gzippo.compress() # To be put back in when it has better caching support
app.use express.static("#{__dirname}/public")

app.use "/api/v1", require("./servers/api/v1")
app.use "/raw", require("./servers/plunks")

app.set "views", "#{__dirname}/views"
app.set "view engine", "jade"
app.set "view options", layout: false

app.use express.logger()
app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.get "/", (req, res) ->
  res.render("index", page: "/")

app.get "/documentation", (req, res) ->
  res.render("documentation", page: "/documentation")

app.get "/about", (req, res) ->
  res.render("about", page: "/about")


app.get /^\/([a-zA-Z0-9]{6})\/(.*)$/, (req, res) ->
  res.local "raw_url", "/raw" + req.url
  res.local "plunk_id", req.params[0]
  res.render "preview"
  
app.get /^\/([a-zA-Z0-9]{6})[^\/]?/, (req, res) -> res.redirect("/#{req.params[0]}/", 301)


app.get /^\/edit(?:\/([a-zA-Z0-9]{6})\/?)?/, (req, res) ->
  res.render("editor", page: "/edit", views: req.param("views", "sidebar editor preview").split(/[ \.,]/).join(" "))


if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Listening on port %d", process.env.PORT || 8080