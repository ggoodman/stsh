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

class exports.Store
  constructor: ({@ttl, @server, @queueSize} = {ttl: 60 * 60 * 24 * 2, server: "", queueSize: 12})->
    @plunks = {}
    @timeouts = {}
    @destructors = {}
    @queue = []
    
  createDestructor: (id) ->
    self = @
    @destructors[id] = ->
      clearTimeout(self.timeouts[id])
      
      self.queue = _.without(self.queue, id)
      
      delete self.plunks[id]
      delete self.timeouts[id]
  
  exists: (uid) -> !!@plunks[uid]
  create: (json, cb) ->
    json.id = uid(6)
    json.token = uid(16)
    json.ttl = @ttl
    json.expires = new cromag(cromag.now() + json.ttl * 1000).toISOString()
    
    json.id = uid(6) while @exists(json.id)
    
    json.url = "#{@server}/#{json.id}/"
    
    file.url = json.url + file.filename for filename, file of json.files
    
    @plunks[json.id] = json
    @timeouts[json.id] = setTimeout(@createDestructor(json.id), json.ttl * 1000)
    @queue.push json.id
    @queue = _.last(@queue, 12)
    
    cb(null, json)
  
  list: (options, cb) ->
    if _.isFunction(options) then [cb, options] = [options, {}]
    
    options = _.defaults options,
      start: 0
      end: 12
    
    self = @
    
    cb null, _.map self.queue, (id) -> self.plunks[id]
  
  fetch: (id, cb) ->
    if plunk = @plunks[id]
      plunk = deepClone(plunk)
      plunk.ttl = Math.floor((cromag.parse(plunk.expires) - cromag.now()) / 1000)
    
    return cb(null, plunk)
  
  destroy: (id, cb) ->
    if destructor = @destructors[id]
      destructor()
    cb(null)