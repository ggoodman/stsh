fs = require("fs")
Cromag = require("cromag")
Backbone = require("backbone")
_ = require("underscore")._


# From connect/utils.js
uid = (len = 6) ->
  keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  key = ""

  while len-- > 0
    key += keyspace.charAt(Math.floor(Math.random() * keyspace.length))

  key


delay = (timeout, callback) -> setTimeout(callback, timeout)

class Collection extends Backbone.Collection
  comparator: (model) -> -Cromag.parse(model.get("updated_at") or model.get("created_at"))
  
  
class Store
  constructor: (options = {}) ->
    self = @
    
    @filename = options.filename or "/tmp/plunker.json"
    @frequency = options.interval or 1000 * 20
    
    @plunks = new Collection
    @timeouts = {}
    
    @plunks.on "reset", (coll) -> coll.each(self.setExpiry)
    @plunks.on "add", self.setExpiry
    
    setInterval(@backup, @frequency)

    @restore()
  
  backup: =>
    self = @
    
    fs.writeFile @filename, JSON.stringify(@plunks.toJSON()), (err) ->
      if err then console.log "Backup failed to: #{self.filename}"
      else console.log "Backup completed to: #{self.filename}"

  restore: =>
    self = @
    
    console.log "Attempting to restore data from: #{@filename}"
    fs.readFile @filename, "utf8", (err, data) ->
      if err then console.log "Failed to restore data: #{self.filename}"
      else self.plunks.reset(JSON.parse(data)) and console.log "Restore succeeded from: #{self.filename}"

  setExpiry: (model) =>
    self = @
    
    @timeouts[model.id] = delay Cromag.parse(model.expires) - Cromag.now(), ->
      self.remove(model)
    @

  list: (start, end, cb) -> cb null, @plunks.toJSON().slice(start, end)
  reserveId: (cb) -> cb null, uid(6) # OH GOD THE CHILDREN
  create: (json, cb) -> cb null, @plunks.add(json).get(json.id).toJSON()
  fetch: (id, cb) -> cb null, @plunks.get(id).toJSON()
  update: (json, cb) -> cb null, @plunks.get(id).set(json).toJSON()
  remove: (id, cb) -> cb null, @plunks.remove(id)
  
store = null

exports.createStore = (config) ->
  store ||= new Store(config)

###
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

        self.queue = _.sortBy self.queue, (id) -> -new Cromag(self.plunks[id].created_at).valueOf()

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
    @timeouts[json.id] = setTimeout(@createDestructor(json.id), Cromag.parse(json.expires) - Cromag.now())
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
    
    return cb null, _.chain(self.plunks).sortBy((plunk) -> new Cromag(plunk.created_at).valueOf()).value()

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