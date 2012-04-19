coffee = require("coffee-script")
express = require("express")
gzippo = require("gzippo")
assets = require("connect-assets")
sharejs = require("share")
_ = require("underscore")._

app = module.exports = express.createServer()


_.extend process.env, require("optimist").argv

# Configure Passport

passport = require("passport")
GitHubStrategy = require("passport-github").Strategy

passport.serializeUser (user, done) ->
  done(null, user)

passport.deserializeUser (obj, done)->
  done(null, obj)

passport.use new GitHubStrategy {
    clientID: process.env.oauth_github_id,
    clientSecret: process.env.oauth_github_secret,
    callbackURL: "http://#{process.env.host}/auth/github/callback"
  }, (accessToken, refreshToken, profile, done) ->
    console.log "AUTH:", arguments...
    profile.token = accessToken
    done(null, profile)


# Configure Subdomains

subdomains = require("express-subdomains")

subdomains
  .use "raw"

app.use subdomains.middleware

app.use assets()
app.use gzippo.staticGzip("#{__dirname}/public")
#app.use gzippo.compress() # To be put back in when it has better caching support
app.use express.static("#{__dirname}/public")

app.use(express.cookieParser())
app.use(express.bodyParser())
app.use(express.session({ secret: "plnkr.co secret key" }))
app.use(passport.initialize())
app.use(passport.session())

app.use "/api/v1", require("./servers/api/v1")
app.use "/raw", require("./servers/plunks")


app.set "views", "#{__dirname}/views"
app.set "view engine", "jade"
app.set "view options", layout: false


app.get "/auth/github", passport.authenticate("github"), (req, res, next) -> next()
app.get "/auth/github/callback", passport.authenticate("github", { failureRedirect: "/" }), (req, res) -> res.redirect("/")


setUser = (req, res, next) ->
  res.locals user: req.user or null
  next()
  
  
app.get "/", setUser, (req, res) ->
  res.render("index", page: "/")

app.get "/documentation", setUser, (req, res) ->
  res.render("documentation", page: "/documentation")

app.get "/about", setUser, (req, res) ->
  res.render("about", page: "/about")

app.get "/logout", (req, res) ->
  req.logout()
  res.redirect('/')

# Start the sharejs server before variable routes
sharejs.server.attach app,
  db:
    type: "none"


app.get /^\/([a-zA-Z0-9]{6})\/(.*)$/, setUser, (req, res) ->
  res.local "raw_url", "http://raw.#{req.headers.host}#{req.url}"
  res.local "plunk_id", req.params[0]
  res.render "preview"

app.get /^\/([a-zA-Z0-9]{6})$/, (req, res) -> res.redirect("/#{req.params[0]}/", 301)


app.get /^\/edit(?:\/([a-zA-Z0-9]{6})\/?)?/, setUser, (req, res) ->
  res.render("editor", page: "/edit", views: req.param("views", "sidebar editor preview").split(/[ \.,]/).join(" "))

app.use express.logger()

if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Listening on port %d", process.env.PORT || 8080