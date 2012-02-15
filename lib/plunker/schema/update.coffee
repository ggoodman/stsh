module.exports =
  type: "object"
  additionalProperties: false
  minProperties: 1
  properties:
    description:
      type: "string"
    index:
      type: "string"
    files:
      type: "object"
      minProperties: 1
      additionalProperties:
        type: [
          type: "null"
        ,
          type: "string"
        ,
          type: "object"
          additionalProperties: false
          properties:
            new_filename:
              type: "string"
            content:
              type: "string"
            mime:
              type: "string"
            encoding:
              type: "string"
        ]