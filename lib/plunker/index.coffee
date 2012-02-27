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
    errors = []
    
    # Update description
    plunk.description = json.description or plunk.description

    if json.files
      changed = _.keys(json.files)
      old_files = {}
      new_files = {}
      
      # Pre-populate the new_files hash with files that should be unaffected
      # Also create a hash of old files
      for filename, file of plunk.files
        new_files[filename] = file unless filename in changed
        old_files[filename] = _.clone(file)

      for filename, file of json.files
        former = old_files[filename]
        
        # Normalize file structure to hash
        if _.isString(file) then file =
          filename: filename
          content: file
          mime: mime.lookup(filename)
        
        # The file is being deleted; don't put it in new_files. Make sure to
        # check against index
        if _.isNull(file)
          unless former then errors.push
            message: "Impossible to delete a file that did not exist"
            field: "files['#{filename}']"
        
        # The file already exists. We may need to
        #  1) Rename the file
        #  2) Update the contents
        #  3) Update the mime type
        else if former
          # Houston, we have a rename!
          if new_name = file.filename and new_name != filename
            if new_files[new_name] then errors.push
              message: "Impossible to rename a file to a filename that already exists"
              field: "files['#{filename}'].filename"
            #else if old_files[new_name] and not json.files[file.filename]?.filename
        
        # This is a new file, therefore requires content
        else
          unless file.content then errors.push
            message: "Content is a required field"
            field: "files['#{filename}'].content"
          else new_files[filename] =
            filename: filename
            content: file.content
            mime: file.mime || mime.lookup(filename)
            
      plunk.files = new_files
    
    # Update index
    plunk.index = json.index or plunk.index

          
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

  index: (cb) -> @store.list(0, 8, cb)
  create: (json, cb) -> @creater.create(json, cb)
  read: (id, cb) -> @store.fetch(id, cb)
  update: (plunk, json, cb) -> @updater.update(plunk, json, cb)
  remove: (id, cb) -> @store.remove(id, cb)

module.exports = do ->
  middleware = null

  createInterface: (config) -> new Interface(config)

  middleware: (config) ->
    middleware ||= new Interface(config)

    (req, res, next) ->
      middleware.config.url ||= "http://#{req.headers.host}"
      req.plunker = middleware
      next()