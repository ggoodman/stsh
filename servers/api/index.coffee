express = require("express")
app = module.exports = express.createServer()

app.use express.logger()


app.use "/v1", require("./v1")


if require.main == module
  app.listen process.env.PORT || 8080
  console.log "API listening on port %d", process.env.PORT || 8080