module.exports =
  port: 5340
  useCache: true
  cacheTTL: 60 * 60 # 1 hour
  kloutApi: require './kloutApi'