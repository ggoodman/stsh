# Plunker

## API

### Create a plunk

`POST  /api/v1/plunk`

Request body:

```json
{
	description: "description" // Optional
	index: "index.html"				// Defaults to "index.html"
	files: {
		"filename.ext": {
			content: "content of file"	// Required, can also be the value of the filename hash
			mime: "text/plain"		// Optional, otherwise guessed
			encoding: "ascii"		// Defaults to "ascii", can also be base64
		}
	}
}
```

Response:

```json
{
	id:	"a13bd3"				// Id of the plunk
	token: "secret token"				// Token that must be passed to PATCH/DELETE a plunk
	url: "http://plunks.com/a13bd3"
	expiry: "ISO Date"
	ttl: 123456					// Number of seconds remaining on the plunk
}
```

### Retrieve a plunk

`GET	/api/v1/plunk/:id`

Response:

```json
	{
		id:	"a13bd3"				// Id of the plunk
		url: "http://plunks.com/a13bd3"
		expiry: "ISO Date"
		ttl: 123456					// Number of seconds remaining on the plunk
		description: "description" // Optional
		index: "index.html"				// Defaults to "index.html"
		files: {
			"filename.ext": {
				content: "content of file"	// Required, can also be the value of the filename hash
				mime: "text/plain"		// Optional, otherwise guessed
			}
		}
	}
```

### Update a plunk

`PATCH	/api/v1/plunk/:id`

Not yet implemented

### Destroy a plunk

`DELETE	/api/v1/plunk/:id`