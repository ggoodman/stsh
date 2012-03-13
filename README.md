# Plunker

Plunker is a website and RESTful API for creating, previewing and sharing web snippets online.

## What is a plunk?

A *plunk* is a web snippet that is composed of an arbitrary number of files that can be viewed online through the Plunker service. Each plunk has:

* **description** (optional) This should be a short description of what the plunk represents
* **index** (optional) This is the filename of the *main* file of the plunk. For  example, this would be 'index.html' for a typical web snippet.
* **expires** (optional) This is the time (formatted per ISO 8601) that the plunk should expire. Plunks that expire are considered *private* and will not appear on the landing page. For example: the preview functionality of the editor uses plunks with short expiry times to run the previews.                                                                                                                 
* **files** (required) This is a hash that maps filenames to their description.

### Plunk files

Each file in the plunk can be presented to the API in either the short or long form.

* **short-form** In this form, the file entry is a mapping of the file to its contents. For example:

  ```json
  {
    "index.html": "<html></html>"
  }
  ```

* **long-form** In this form, the file entry is a mapping of the file to a hash representing the file. All file entries returned by the API will be in long-form.

  ```json
  {
    "index.html": {
      filename: "index.html",
      content: "<html></html>"
    }
  }
  ```

## What is so cool about Plunker?

Many other amazing online services impose certain restrictions on the composition of their snippets. For example, services will typically enforce that each snippet has one html file, one css file and one javascript file. **What if you want two javascript files?!**

Plunker is neat because it enables more creativity and flexibility in the definition of what can be in plunks.

* Do you want a json file that's loaded over XHR? *OK, no problem!*
* Do you want to load coffee-script, less, stylus or handlebars templates from the client-side? *Have at it!*

## Running Plunker

Running Plunker locally is really easy. You only need to have node.js and npm installed to get started.

```
git clone https://ggoodman@github.com/ggoodman/stsh.git
cd stsh
npm install
node server.js
```

There is no configuration necessary and Plunker runs without any sort of backend database. Note that plunks will be saved to and restored from `/tmp/plunks.json`. For the save/restore feature to work, the user running Plunker must have read/write access to `/tmp`.