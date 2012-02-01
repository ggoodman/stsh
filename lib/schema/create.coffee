module.exports =
  type: "object"
  properties:
    description:
      type: "string"
    index:
      type: "string"
      default: "index.html"
    files:
      required: true
      type: [
        type: "array"
        minItems: 1
        items:
          type: "object"
          properties:
            filename:
              type: "string"
              required: true
            content:
              type: "string"
              required: true
            mime:
              type: "string"
            encoding:
              type: "string"
      ,
        type: "object"
        minProperties: 1
        items: 
          type: "string"
      ]