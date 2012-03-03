module.exports =
  type: "object"
  additionalProperties: false
  minProperties: 1
  properties:
    id:
      type: "string"
    description:
      type: "string"
    index:
      type: "string"
    expires:
      type: "string"
    files:
      type: "object"
      additionalProperties:
        type: [
          type: "null"
        ,
          type: "string"
        ,
          type: "object"
          additionalProperties: false
          properties:
            filename:
              type: "string"
              retuired: true
            content:
              type: "string"
            mime:
              type: "string"
        ,
          type: "object"
          additionalProperties: false
          minProperties: 1
          properties:
            content:
              type: "string"
            mime:
              type: "string"
        ]