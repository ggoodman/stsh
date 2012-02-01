schema = require("json-schema")
mime = require("mime")
_ = require("underscore")._

module.exports = (store) ->
  load: (req, id, cb) ->
    # Fetch the plunk (async)
    store.fetch id, (err, plunk) ->
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

    
  create: (req, res, next) ->
    json = _.clone(req.body)
    
    # Validate the json against the json-schema
    {valid, errors} = schema.validate(json, require("../lib/schema/create"))
    
    # Trigger an appropriate error if validation fails
    return next({number: 422, message: "Validation failed", errors: errors }) unless valid
    
    # Files can be provided as a hash of filename => contents or filename => file descriptor
    # This code normalizes them to the latter format
    _.each json.files, (file, filename) ->
      if _.isString(file) then file = { content: file }
      file.filename = filename
      file.mime ||= mime.lookup(file.filename)
      file.encoding ||= mime.charsets.lookup(file.mime)
      
      json.files[filename] = _.clone(file)
    
    return next({number: 422, message: "Validation failed", errors: [{field: "index", message: "No file defined for index"}]}) unless json.files[json.index]
    
    store.create json, (err, plunk) ->
      if err then next(err)
      else res.json(plunk)
  
  show: (req, res, next) ->
    delete req.plunk.token unless req.authorized
    
    res.json(req.plunk)