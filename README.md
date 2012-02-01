# Plunker

## API

### Create a plunk

`POST  /api/v1/plunk`

Request body:

```json
{
  "description": "Optional description of the plunk", // Optional
  "index": "index.html",  // Optional (if provided must have a corresponding file entry, otherwise must provide index.html)
  "files": { // Required
    // Inline format below for defining files (filename => content)
    "index.html": "<html><head><link rel=\"stylesheet\" href=\"style/style.css\" /><script src=\"https://raw.github.com/JerrySievert/cromagjs/master/cromag.js\"></script></head><body><h1>Header</h1></body><p>If the header above is red, that means that both this file (index.html) and the stylesheet (style.css) were property served by plunker.</p></html>",
    // Complete format below for defining files (filename => file description)
    "style/style.css": {
      "mime": "text/css", // Optional (will be guessed otherwise based on filename)
      "encoding": "utf-8", // Optional (will be guessed otherwise based on mime type)
      "content": "h1 { color: red }" // Required if using object format
    }
  }
}
```

Response:

```json
{
  "ttl": 172774, // Time-to-live for the plunk in seconds
  "expires": "2012-02-03T16:46:19.013Z", // The ISO 8601 timestamp of the expiry time
  "token": "6ugRyNV8hC8MzYmG", // The _private_ token that should be retained to allow updating the plunk
  "files": {
    "style.css": {
      "encoding": "UTF-8",
      "filename": "style.css",
      "content": "h1 { color: red }",
      "mime": "text/css"
    },
    "index.html": {
      "encoding": "UTF-8",
      "filename": "index.html",
      "content": "<html><head><link rel=\"stylesheet\" href=\"style.css\" /><script src=\"https://raw.github.com/JerrySievert/cromagjs/master/cromag.js\"></script></head><body><h1>Header</h1></body><p>If the header above is red, that means that both this file (index.html) and the stylesheet (style.css) were property served by plunker.</p></html>",
      "mime": "text/html"
    }
  },
  "url": "http://stsh.ggoodman.c9.io/6oNzNy/", // The public url that can be used to preview the plunk
  "id": "6oNzNy", // The plunk's internal id (not guaranteed to map to the url)
  "index": "index.html" // The default file to be served at the url
}
```

### Retrieve a plunk

`GET	/api/v1/plunk/:id`

Response:

```json
{
  "ttl": 172774, // Time-to-live for the plunk in seconds
  "expires": "2012-02-03T16:46:19.013Z", // The ISO 8601 timestamp of the expiry time
  "token": "6ugRyNV8hC8MzYmG", // This will only be returned if the correct token was provided in the query string or in the Authorization header
  "files": {
    "style.css": {
      "encoding": "UTF-8",
      "filename": "style.css",
      "content": "h1 { color: red }",
      "mime": "text/css"
    },
    "index.html": {
      "encoding": "UTF-8",
      "filename": "index.html",
      "content": "<html><head><link rel=\"stylesheet\" href=\"style.css\" /><script src=\"https://raw.github.com/JerrySievert/cromagjs/master/cromag.js\"></script></head><body><h1>Header</h1></body><p>If the header above is red, that means that both this file (index.html) and the stylesheet (style.css) were property served by plunker.</p></html>",
      "mime": "text/html"
    }
  },
  "url": "http://stsh.ggoodman.c9.io/6oNzNy/", // The public url that can be used to preview the plunk
  "id": "6oNzNy", // The plunk's internal id (not guaranteed to map to the url)
  "index": "index.html" // The default file to be served at the url
}
```

### Update a plunk

`PATCH	/api/v1/plunk/:id`

Not yet implemented

### Destroy a plunk

`DELETE	/api/v1/plunk/:id`

Not yet implemented