fs = require("fs")
cromag = require("cromag")
_ = require("underscore")._


# From connect/utils.js
uid = (len = 6) ->
  keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  key = ""

  while len-- > 0
    key += keyspace.charAt(Math.floor(Math.random() * keyspace.length))

  key

deepClone = (obj) ->
  if _.isArray(obj)
    clone = _.map obj, (elem) -> deepClone(elem)
  else if typeof obj == 'object'
    clone = {}

    _.each obj, (val, key) -> clone[key] = deepClone(val)
  else
    clone = obj

  clone

class Store
  constructor: ({@ttl, @server, @queueSize} = {ttl: 60 * 60 * 24 * 2, server: "", queueSize: 12})->
    @plunks = {}
    @timeouts = {}
    @destructors = {}
    @queue = []

    self = @

    console.log "Attempting to restore data"

    fs.readFile "/tmp/backup.json", "utf8", (err, data) ->
      if err then console.log "Failed to restore data"
      else
        self._add(plunk) for id, plunk of JSON.parse(data)
        console.log "Restore completed"

        self.queue = _.sortBy self.queue, (id) -> -new cromag(self.plunks[id].created_at).valueOf()

    setInterval @backup, 1000 * 30 # Every 30s

  backup: =>
    fs.writeFile "/tmp/backup.json", JSON.stringify(@plunks), (err) ->
      if err then console.log "Backup failed"
      else console.log "Backup completed"


  createDestructor: (id) ->
    self = @
    @destructors[id] = ->
      clearTimeout(self.timeouts[id])

      self.queue = _.without(self.queue, id)

      delete self.plunks[id]
      delete self.timeouts[id]

  exists: (uid) -> !!@plunks[uid]
  _add: (json) ->
    @plunks[json.id] = json
    @timeouts[json.id] = setTimeout(@createDestructor(json.id), cromag.parse(json.expires) - cromag.now())
    @queue.unshift json.id
    @queue = _.first(@queue, 12)

  create: (json, cb) ->
    @_add json

    cb(null, json)

  update: (json, cb) ->
    console.log "update", arguments...
    @plunks[json.id] = json

    cb(null, deepClone(json))

  reserveId: (cb) -> cb(null, uid(6))

  list: (options, cb) ->
    if _.isFunction(options) then [cb, options] = [options, {}]

    options = _.defaults options,
      start: 0
      end: 12

    self = @
    
    return cb null, _.chain(self.plunks).sortBy((plunk) -> new cromag(plunk.created_at).valueOf()).value()

    cb null, _.map self.queue, (id) -> deepClone(self.plunks[id])

  fetch: (id, cb) ->
    if plunk = @plunks[id]
      plunk = deepClone(plunk)

    return cb(null, plunk)

  remove: (id, cb) ->
    if destructor = @destructors[id]
      destructor()
    cb(null)

store = null

exports.createStore = (config) ->
  store ||= new Store(config)