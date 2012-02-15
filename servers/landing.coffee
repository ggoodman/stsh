express = require("express")
app = module.exports = express.createServer()

app.configure ->
  app.set "views", "#{__dirname}/../views"
  app.set "view engine", "jade"
  app.set "view options", layout: false


app.get "/", (req, res, next) ->
  res.render("index")


if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Landing page listening on port %d", process.env.PORT || 8080