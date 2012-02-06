schema = require("./validate")
mime = require("mime")
_ = require("underscore")._

module.exports = (store) ->
  create: (json, cb) ->    
    # Validate the json against the json-schema
    {valid, errors} = schema.validate(json, require("../lib/schema/create"))
    
    # Trigger an appropriate error if validation fails
    return cb({number: 422, message: "Validation failed", errors: errors }) unless valid
    
    # Files can be provided as a hash of filename => contents or filename => file descriptor
    # This code normalizes them to the latter format
    _.each json.files, (file, filename) ->
      if _.isString(file) then file = { content: file }
      file.filename = filename
      file.mime ||= mime.lookup(file.filename)
      file.encoding ||= mime.charsets.lookup(file.mime)
      
      json.files[filename] = _.clone(file)
      
    json.index ||= do ->
      filenames = _.keys(json.files)
      
      if "index.html" in filenames then "index.html"
      else
        html = _.filter filenames, (filename) -> /.html?$/.test(filename)
        
        if html.length then html[0]
        else filenames[0]
    
    # Check to see that the index points to a legitimate file
    return cb({number: 422, message: "Validation failed", errors: [{property: "index", message: "No file defined for index"}]}) unless json.files[json.index]
    
    store.create(json, cb)
  
  read: (id, cb) -> store.fetch(id, cb)
  destroy: (id, cb) -> store.destroy(id, cb)
  list: (cb) -> store.list(cb)
