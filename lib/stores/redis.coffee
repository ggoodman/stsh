redis = require("redis")
Cromag = require("cromag")

createKey = (len = 8) ->
  keyspace = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  key = ""
  
  while len-- > 0
    key += keyspace.charAt(Math.floor(Math.random() * keyspace.length))
    
  key

module.exports = class
  constructor: (config) ->
    @db = redis.createClient config.port, config.host
    if config.pass
      @db.auth config.pass, (err) ->
        if err then throw err
  
  sync: (method, model, options) => @[method](model, options)
  
  create: (model, options) ->
    json = model.toJSON()
    json.id = createKey(8)
    json.token = createKey(16)
    json.ttl = 60 * 60 * 24 * 2
    json.expires = Cromag.now().add(seconds: json.ttl).toISOString()
    
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
      trnx.hmset "plunk:#{json.id}:file:#{f.id}",
        id: f.id
        filename: f.filename
        mime: f.mime
        encoding: f.encoding
      trnx.expire "plunk:#{json.id}:file:#{f.id}", json.ttl
      
      trnx.sadd "plunk:#{json.id}:files", f.id
      
      json.files.push f
    
    trnx.exec (err, replies) ->
  
  read: (model, options) ->
    
