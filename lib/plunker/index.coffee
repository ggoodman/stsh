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
    
    # See http://regexlib.com/REDetails.aspx?regexp_id=3344
    iso8601regex = /^(?:(?=[02468][048]00|[13579][26]00|[0-9][0-9]0[48]|[0-9][0-9][2468][048]|[0-9][0-9][13579][26])\d{4}(?:(-|)(?:(?:00[1-9]|0[1-9][0-9]|[1-2][0-9][0-9]|3[0-5][0-9]|36[0-6])|(?:01|03|05|07|08|10|12)(?:\1(?:0[1-9]|[12][0-9]|3[01]))?|(?:04|06|09|11)(?:\1(?:0[1-9]|[12][0-9]|30))?|02(?:\1(?:0[1-9]|[12][0-9]))?|W(?:0[1-9]|[1-4][0-9]|5[0-3])(?:\1[1-7])?))?)$|^(?:(?![02468][048]00|[13579][26]00|[0-9][0-9]0[48]|[0-9][0-9][2468][048]|[0-9][0-9][13579][26])\d{4}(?:(-|)(?:(?:00[1-9]|0[1-9][0-9]|[1-2][0-9][0-9]|3[0-5][0-9]|36[0-5])|(?:01|03|05|07|08|10|12)(?:\2(?:0[1-9]|[12][0-9]|3[01]))?|(?:04|06|09|11)(?:\2(?:0[1-9]|[12][0-9]|30))?|(?:02)(?:\2(?:0[1-9]|1[0-9]|2[0-8]))?|W(?:0[1-9]|[1-4][0-9]|5[0-3])(?:\2[1-7])?))?)$/
    
    if json.expires and not iso8601regex.test(json.expires)
      @valid = false
      @errors ||= []
      @errors.push
        message: "Expiry date must be a valid ISO8601 date"
        field: "expires"

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
        url: "#{self.config.url}/api/v1/plunks/#{id}"
        html_url: "#{self.config.url}/#{id}/"
        raw_url: "#{self.config.url}/raw/#{id}/"

      for filename, file of json.files
        file.url = "#{json.url}/#{filename}"
        file.html_url = "#{json.html_url}#{filename}"
        file.raw_url = "#{json.raw_url}#{filename}"

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
          if (new_name = file.filename) and new_name != filename
            console.log filename, file
            console.log "new_files", new_files
            if new_files[new_name] then errors.push
              message: "Impossible to rename a file to a filename that already exists"
              field: "files['#{filename}'].filename"
            else new_files[new_name] =
              filename: new_name
              content: file.content or former.content
              mime: file.mime || mime.lookup(filename)
          # Not a rename, but change to existing file
          else new_files[new_name] =
            filename: filename
            content: file.content or former.content
            mime: file.mime or former.mime
        
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
    
    if _.keys(plunk.files).length <= 0 then errors.push
      message: "Minimum of 1 file required"
      field: "files"
    
    else
      # Update index
      plunk.files[plunk.index] or plunk.index = do ->
        filenames = _.keys(plunk.files)
  
        if "index.html" in filenames then "index.html"
        else
          html = _.filter filenames, (filename) -> /.html?$/.test(filename)
  
          if html.length then html[0]
          else filenames[0]

    plunk.updated_at = new Cromag().toISOString()
          
    if errors.length then next {message: "Validation failed", errors: errors}
    else next(null, plunk)


  update: (plunk, json, cb) ->
    self = @
    
    json = JSON.parse(json) if _.isString(json) 
    
    self.validate json, (err, json) ->
      if err then cb(err)
      else self.handleFileChanges plunk, json, (err, json) ->
        if err then cb(err)
        else self.store.update plunk, json, cb

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