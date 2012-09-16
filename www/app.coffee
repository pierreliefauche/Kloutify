request   = require 'request'
memcache  = require 'memcache'
memjs     = require 'memjs'
config    = require './config'

###
  Configure cache client to store Klout scores
###
if config.useCache
  cache = if process.env.MEMCACHE_USERNAME then memjs.Client.create() else new memcache.Client()
  cache.on 'error', (error)->
    console.log "Cache client error: #{error}"
    cache = null
  .on 'timeout', ()->
    console.log "Cache client did timeout"
  .connect()

###
  Klout API
###
getKloutScore = (username, callback) ->
  defaultScore = 10
  resource = "http://api.klout.com/1/klout.json?users=#{username}&key=#{config.kloutApi.key}"
  request resource, (error, response, body)->
    unless error or response.statusCode isnt 200
      try
        data = JSON.parse body
        if data.status is 200 and typeof data.users is 'object' and data.users.length
          return callback data.users[0].kscore or defaultScore

      catch e
        error = e

    # An error happened
    console.log "Error while getting Klout score of '#{username}': #{error}"
    return callback defaultScore

###
  Helpers
###

# Send JSON over the response
sendJson = (res, json)->
  json = JSON.stringify json unless typeof json is 'string'
  res.send json,
    'Access-Control-Allow-Origin': '*'
    'Content-Type': 'application/json'

# Cache middleware: immediately respond cached response if available,
# otherwise hijack the response object to cache its body
cacheable = (req, res, next)->
  next() unless cache
  cache.get req.url, (error, data)->
    if data and not error
      data = JSON.parse data
      res.send data.body, data.headers, data.status
    else
      _send = res.send
      res.send = (body, headers, status)->
        res.send = _send
        res.send body, headers, status
        data = JSON.stringify
          body: body
          headers: headers
          status: status
        cache.set req.url, data, (()->), config.cacheTTL
      next()

###
  Web server
###
require('zappa').run process.env.PORT or config.port, ->

  @use 'static', cacheable

  # Legacy
  @get '/klout/:username.json', ()->
    getKloutScore @params.username, (score) =>
      sendJson @response, {'kscore': score}

  @get '/2/twitter/:username.json', ()->
    getKloutScore @params.username, (score) =>
      sendJson @response,
        'twitter': @params.username
        'score': score

  @get '/', ->
    @render 'index'

  @get '*', ->
    @redirect '/'

  @view index: ->
    div id: 'container', ->
      iframe allowtransparency: 'true', frameborder: '0', scrolling: 'no', src: 'http://platform.twitter.com/widgets/tweet_button.html?count=none&text=Kloutify%3A%20Klout%20scores%20right%20inside%20any%20website'
      h1 'Kloutify'
      h2 ->
        a href: 'http://klout.com', onclick: "_gaq.push(['_trackEvent', 'External', 'Visit', 'Klout']);", target:'_blank', 'Klout'
        text ' scores right inside '
        a href: 'http://twitter.com', class: 'overlined', onclick: "_gaq.push(['_trackEvent', 'External', 'Visit', 'Twitter']);", target:'_blank', 'Twitter.com'
        strong ' any website'
      img alt: 'Screenshot of Kloutify used on Twitter.com', src: '/newsycombinator.png'
      img alt: 'Screenshot of Kloutify used on Twitter.com', class: 'last', src: '/techcrunch.png'
      p class:'install', ->
        text 'Install extension for '
        a href: 'https://chrome.google.com/webstore/detail/pbkmilgjhlpojnifhokfkkbdkpdoofij', class:'download', target:'_blank', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Chrome']);", 'Chrome'
        text ', '
        a href: 'http://addons.mozilla.org/firefox/addon/kloutify/', class:'download', target:'_blank', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Firefox']);", 'Firefox'
        text ' or '
        a href: '/extension/kloutify.safariextz', class:'download', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Safari']);", target:'_blank', 'Safari'
      p class: 'profile', ->
        text 'Browser extensions by '
        a href: 'http://twitter.com/pierreliefauche', class: 'user-profile-link', onclick: "_gaq.push(['_trackEvent', 'Profile', 'Visit', 'pierreliefauche']);", target:'_blank', '@pierreliefauche'


  @view layout: ->
    doctype 5
    html ->
      head ->
        meta charset: 'utf-8'
        title 'Kloutify | Klout scores right inside any website'
        meta name:'description', content:'Kloutify is a browser extension displaying Klout scores when hovering a Twitter username on any website'
        # base href: 'http://kloutify.com/'
        link rel: 'icon', type: 'image/x-icon', href: '/favicon.ico'
        link rel: 'shortcut icon', type: 'image/x-icon', href: '/favicon.ico'
        link rel: 'stylesheet', href: '/main.css'
        script type: 'text/javascript', '''
          var _gaq = _gaq || [];
            _gaq.push(['_setAccount', 'UA-24838928-1']);
            _gaq.push(['_trackPageview']);

            (function() {
              var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
              ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
              var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
        '''
      @body