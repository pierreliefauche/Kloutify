module.exports =
  port: 5340
  useCache: true
  cacheTTL: 60 * 60 # 1 hour
  defaultScore: 10
  kloutApi: require './kloutApi'