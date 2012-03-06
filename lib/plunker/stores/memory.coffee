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
    
    @options = _.defaults options,
      filename: "/tmp/plunker.json"
      size: 1000
      interval: 1000 * 20
      backup: true
    
    @filename = @options.filename
    @frequency = @options.interval
    
    @plunks = new Collection
    @timeouts = {}
    
    @plunks.on "reset", (coll) -> coll.each(self.setExpiry)
    @plunks.on "add", self.setExpiry
    @plunks.on "remove", self.clearExpiry
    
    @plunks.on "reset add", ->
      # Defer to next tick or something around then
      delay 1, ->
        while self.plunks.length > self.options.size
          self.plunks.remove self.plunks.at(self.plunks.length - 1)

    
    if @options.backup
      @plunks.on "add remove", _.throttle(@backup, @options.interval)
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
      else
        plunks = JSON.parse(data)
        plunks = _.map plunks, (json) ->
          if matches = json.html_url.match(/^(http:\/\/[^\/]+)(.+)$/)
            json.raw_url = "#{matches[1]}/raw#{matches[2]}"
            
            for filename, file of json.files
              file.raw_url = json.raw_url + filename
          json

        self.plunks.reset(plunks) and console.log "Restore succeeded from: #{self.filename}"
  
  shrink: =>
    if @plunks.length > @options.size
      @plunks.remove @plunks.at(@plunks.length - 1)
      

  setExpiry: (model) =>
    self = @
    
    if model.get("expires")
      @timeouts[model.id] = delay Cromag.parse(model.get("expires")) - Cromag.now(), ->
        self.plunks.remove(model)
    @

  clearExpiry: (model) =>
    clearTimeout(@timeouts[model.id]) if model.id and model.get("expires")
    @

  list: (start, end, cb) -> cb null, _.reject(@plunks.toJSON(), (plunk) -> !!plunk.expires).slice(start, end)
  reserveId: (cb) -> cb null, uid(6) # OH GOD THE CHILDREN
  create: (json, cb) -> cb null, @plunks.add(json).get(json.id).toJSON()
  fetch: (id, cb) ->
    if plunk = @plunks.get(id) then cb null, plunk.toJSON()
    else cb()
  update: (plunk, json, cb) ->
    if plunk = @plunks.get(plunk.id) then cb null, plunk.set(json).toJSON()
    else cb(message: "No such plunk")
  remove: (id, cb) -> cb null, @plunks.remove(id)
  
store = null

exports.createStore = (config) ->
  store ||= new Store(config)

