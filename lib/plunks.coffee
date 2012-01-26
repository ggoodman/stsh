mime = require("mime")
Backbone = require("backbone")
_ = require("underscore")._


class File extends Backbone.Model
  idAttribute: "filename"
  
  initialize: ->
  
  initialize: (json) ->
    json.mime ||= mime.lookup(json.filename)
    json.encoding ||= mime.charsets.lookup(json.mime)
    
    @set json, silent: true

class Files extends Backbone.Collection
  model: File


class Plunk extends Backbone.Model
  defaults:
    description: ""
    index: "index.html"
    
  url: -> @id

  initialize: (data) ->
    console.log "Created plunk", @toJSON()
    
    unless _.isArray(data.files)
      data.files = _.map data.files, (file, filename) ->
        if _.isObject(file)
          file.filename = filename
          file
        else if _.isString(file)
          { filename: filename, content: file }
        else throw "Invalid plunk: Files must be a hash of filenames to contents or file descriptors"
    
    unless _.isArray(data.files) then throw "Invalid plunk: files must be an array"
    
    @files = new Files(data.files)
    @unset "files", silent: true
    
  validate: (data) ->
    console.log "PLUNK.validate", arguments...

    return
  
  parse: (data) ->
    console.log "PLUNK.parse", arguments...
    
    @files = new Files(data.files)
    
    delete data.files
    
    data
    
  toJSON: ->
    json = super()
    if @files then json.files = @files.toJSON()
    json

class Plunks extends Backbone.Collection
  model: Plunk

module.exports = {Plunk, Plunks}