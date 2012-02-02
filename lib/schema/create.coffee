module.exports =
  type: "object"
  additionalProperties: false
  properties:
    description:
      type: "string"
    index:
      type: "string"
      default: "index.html"
    additionalProperties: false
    files:
      required: true
      type: "object"
      minProperties: 1
      additionalProperties:
        type: [
          type: "string"
        ,
          type: "object"
          additionalProperties: false
          properties:
            content:
              type: "string"
              required: true
            mime:
              type: "string"
            encoding:
              type: "string"
        ]