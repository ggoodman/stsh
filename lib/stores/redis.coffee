redis = require("redis")
async = require("async")
Cromag = require("cromag")
_ = require("underscore")._

createKey = (len = 8) ->
  keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  key = ""
  
  while len-- > 0
    key += keyspace.charAt(Math.floor(Math.random() * keyspace.length))
    
  key

module.exports.Store = class
  constructor: (config) ->
    @db = redis.createClient config.port, config.host
    if config.pass
      @db.auth config.pass, (err) ->
        if err then throw err

    @db.on "connect", -> console.log "REDIS.connect", arguments...
    @db.on "error", -> console.error "REDIS.error", arguments...
  
  sync: (method, model, options) => @[method](model, options)
  
  create: (model, options) ->
    json = model.toJSON()
    json.id = createKey(8)
    json.token = createKey(16)
    json.ttl = 60 * 60 * 24 * 2
    json.expires = new Cromag().addSeconds(json.ttl).toISOString()
    
    trnx = @db.multi()
    trnx.hmset "plunk:#{json.id}",
      id: json.id
      description: json.description
      token: json.token
      index: json.index
      ttl: json.ttl
      expires: json.expires
    trnx.expire "plunk:#{json.id}", json.ttl
    
    json.files = []
    
    model.files.each (file, i) ->
      f = file.toJSON()
      f.id = "#{json.id}-#{i}"
      trnx.hmset "file:#{f.id}",
        id: f.id
        content: f.content
        filename: f.filename
        mime: f.mime
        encoding: f.encoding
      trnx.expire "file:#{f.id}", json.ttl
      
      trnx.sadd "plunk:#{json.id}:files", f.id
      
      json.files.push f
    
    trnx.exec (err, replies) ->
      console.log "Success", json
      
      if err then options.error(err)
      else options.success(json)
  
  read: (model, options) ->
    unless model.id then options.error "Missing id"
    
    db = @db
    json = model.toJSON()
    
    async.parallel [
      (cb) -> db.hgetall "plunk:#{model.id}", cb
      (cb) -> db.sort "plunk:#{model.id}:files", "BY", "nosort", cb
    ], (err, [hash, files]) ->
      if err then options.error(err)
      else if _.isEmpty(hash) then options.error("Plunk not found")
      else
        console.log "READ.files", files
        _.extend json, hash

        loadFile = (id, cb) -> db.hgetall "file:#{id}", cb
        
        async.map files, loadFile, (err, files) ->
          if err then options.error(err)
          else
            json.files = files
            
            console.log "READ.success", json
            options.success(json)