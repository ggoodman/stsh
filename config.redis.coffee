module.exports =
  server: "http://hostname.com"
  ttl: 60 * 60 * 24 * 2
  store: "redis"
  redis:
    host: "redis.hostname.com"
    port: 9724
    pass: "secret redis password" # Optional, of course