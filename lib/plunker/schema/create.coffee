module.exports =
  type: "object"
  additionalProperties: false
  properties:
    description:
      type: "string"
    index:
      type: "string"
    expires:
      type: "string"
    source:
      type: "object"
      properties:
        name:
          type: "string"
          required: true
        url:
          type: "string"
          required: true
    author:
      type: "object"
      properties:
        name:
          type: "string"
          required: true
        url:
          type: "string"
          required: true
        avatar_url:
          type: "string"
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