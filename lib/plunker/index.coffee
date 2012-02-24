mime = require("mime")
validator = require("./validate")
Cromag = require("cromag")
_ = require("underscore")._

# From connect/utils.js
uid = (len = 16) ->
  keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  key = ""

  while len-- > 0
    key += keyspace.charAt(Math.floor(Math.random() * keyspace.length))

  key

class Creater
  constructor: (@store, @config) ->

  validate: (json, next) ->
    {@valid, @errors} = validator.validate(json, require("./schema/create"))

    unless @valid then return next
      message: "Validation failed"
      errors: @errors

    next null, json

  mapFiles: (json, next) ->
    _.each json.files, (file, filename) ->
      if _.isString(file) then file = { content: file }
      file.filename = filename
      file.mime ||= mime.lookup(file.filename)

      json.files[filename] = _.clone(file)

    json.index ||= do ->
      filenames = _.keys(json.files)

      if "index.html" in filenames then "index.html"
      else
        html = _.filter filenames, (filename) -> /.html?$/.test(filename)

        if html.length then html[0]
        else filenames[0]

    unless json.files[json.index] then return next
      message: "Validation failed"
      errors: [
        message: "No file defined for index"
        property: "index"
      ]

    next null, json

  addFields: (json, next) ->
    self = @
    @store.reserveId (err, id) ->
      if err then return next(err)

      now = new Cromag()

      _.extend json,
        id: id
        token: uid()
        created_at: now.toISOString()
        expires: now.addSeconds(self.config.ttl).toISOString()
        url: "#{self.config.url}/api/v1/plunks/#{id}"
        html_url: "#{self.config.url}/#{id}/"

      for filename, file of json.files
        file.url = "#{json.url}/#{filename}"
        file.html_url = "#{json.html_url}#{filename}"

      next(null, json)

  create: (json, cb) ->
    self = @

    self.validate json, (err, json) ->
      if err then cb(err)
      else self.mapFiles json, (err, json) ->
        if err then cb(err)
        else self.addFields json, (err, json) ->
          if err then cb(err)
          else self.store.create json, cb


class Updater
  constructor: (@store, @config) ->

  validate: (json, next) =>
    {@valid, @errors} = validator.validate(json, require("./schema/update"))
    
    unless @valid then return next
      message: "Validation failed"
      errors: @errors

    next null, json

  handleFileChanges: (plunk, json, next) ->
    old_files = _.clone(plunk.files)

    errors = []
    
    plunk.description = json.description or plunk.description
    plunk.index = json.index or plunk.index

    if json.files
      for filename, new_file of json.files
        old_file = _.clone(plunk.files[filename])
        
        # new_file is null so we're trying to delete
        if _.isNull(new_file)
          unless old_file then errors.push
            message: "Cannot delete a file that does not exist"
            property: "files['#{filename}']"
          else delete old_files[filename]

        # new_file is a string so we're changing contents or adding a new file
        else if _.isString(new_file) then old_files[filename] =
          content: new_file
          filename: filename
          mime: mime.lookup(filename)
        
        else
          if new_file.filename? and new_file.filename != filename then errors.push
            message: "The filename key and filename attribute must match"
            property: "files['#{filename}'].filename"
          # File existed, therefore fields populated
          else if old_file
            new_file.mime ||= if new_file.filename then mime.lookup(new_file.filename) else old_file.mime
            new_file.filename ||= old_file.filename
            new_file.content ||= old_file.content
            old_files[new_file.filename] = new_file
          else
            new_file.filename = filename
            new_file.mime ||= mime.lookup(filename)
            new_file.content ||= old_file.content
            old_files[new_file.filename] = new_file
        plunk.files = old_files
          
    if errors.length then next(errors)
    else next(null, plunk)


  update: (plunk, json, cb) ->
    self = @
    
    json = JSON.parse(json) if _.isString(json) 
    
    self.validate json, (err, json) ->
      if err then cb(err)
      else self.handleFileChanges plunk, json, (err, json) ->
        if err then cb(err)
        else self.store.update json, cb

class Interface
  constructor: (config = {}) ->
    @config = _.defaults config,
      ttl: 60 * 60 * 24 * 2
      url: ""
      store: "memory"

    @store = require("./stores/#{config.store}").createStore(config)

    @creater = new Creater(@store, config)
    @updater = new Updater(@store, config)

  index: (cb) -> @store.list(cb)
  create: (json, cb) -> @creater.create(json, cb)
  read: (id, cb) -> @store.fetch(id, cb)
  update: (plunk, json, cb) -> @updater.update(plunk, json, cb)
  delete: (id, cb) -> @store.delete(id, cb)

module.exports = do ->
  middleware = null

  createInterface: (config) -> new Interface(config)

  middleware: (config) ->
    middleware ||= new Interface(config)

    (req, res, next) ->
      middleware.config.url ||= "http://#{req.headers.host}"
      req.plunker = middleware
      next()