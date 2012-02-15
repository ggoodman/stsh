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
        expires: now.addSeconds(self.config.ttl)
        url: "#{self.config.url}/#{id}/"

      file.url = "#{json.url}/#{filename}" for filename, file of json.files

      self.store.create(json, next)

  create: (json, cb) ->
    self = @

    self.validate json, (err, json) ->
      if err then cb(err)
      else self.mapFiles json, (err, json) ->
        if err then cb(err)
        else self.addFields json, cb


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
    new_files = {}

    errors = []

    if json.files
      for filename, new_file of json.files
        old_file = old_files[filename]

        if _.isString(new_file) then new_file =
          content: file
          filename: filename
          mime: mime.lookup(filename)

        # This is a modification to an existing file
        if old_file
          new_file = _.defaults new_file, old_file

          # Change the name of an existing file
          new_files[new_file.filename] = new_file

          # Delete the old file from old_files hash
          delete old_files[filename]


  update: (plunk, json, cb) ->
    @validate json, (err, json) ->
      if err then return cb(err)

      @
    async.waterfall [@store.fetch()]

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
  update: (id, json, cb) -> @updater.update(json, cb)
  delete: (id, cb) -> @store.delete(id, cb)

module.exports = do ->
  createInterface: (config) -> new Interface(config)

  middleware: (config) ->
    interface = new Interface(config)

    (req, res, next) ->
      interface.config.url ||= req.headers.host
      req.plunker = interface
      next()