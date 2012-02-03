schema = require("json-schema")
mime = require("mime")
_ = require("underscore")._

module.exports = (store) ->
  plunks = require("../lib/plunks")(store)

  load: (req, id, cb) ->
    # Fetch the plunk (async)
    plunks.fetch id, (err, plunk) ->
      return cb(err) if err
      
      # Although not necessarily the 'appropriate' place to put this check for
      # a token passed in the query string or in the Authorization header.
      if req.query.token and req.query.token == plunk.token
        req.authorized = true
      else if auth = req.header("Authorization")
        [token] = auth.match(/^token (\S+)$/i)
        
        if token and token == plunk.token
          req.authorized = true
      
      cb(null, plunk)

  index: (req, res, next) ->
    plunks.list (err, plunks) ->
      return next({number: 500, message: err}) if err
      
      _.each plunks, (plunk) ->
        delete plunk.token 
      
      res.json(plunks)
    
  create: (req, res, next) ->
    plunks.create req.body, (err, plunk) ->
      return next(err) if err
      
      res.json(plunk, 201)

  
  show: (req, res, next) ->
    delete req.plunk.token unless req.authorized
    
    res.json(req.plunk)
  
  destroy: (req, res, next) ->
    return next({number: 404, message: "Not found"}) unless req.authorized
    
    store.destroy req.plunk.id, (err) ->
      return next({number: 500, message: err}) if err
      return res.send(204)
      