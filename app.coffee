coffee = require("coffee-script")
express = require("express")
gzippo = require("gzippo")

app = module.exports = express.createServer()

app.configure ->
  #app.use express.logger()
  app.use express.compiler
    src: "#{__dirname}/assets"
    dest: "#{__dirname}/public"
    enable: ["coffeescript"]
  app.use gzippo.staticGzip("#{__dirname}/public")
  app.use gzippo.compress()
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })


app.use "/api", require("./servers/api")
app.use require("./servers/landing")
app.use require("./servers/plunks")


if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Listening on port %d", process.env.PORT || 8080