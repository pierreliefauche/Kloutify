request   = require 'request'
memcache  = require 'memcache'
config    = require './config'

###
Configure cache client to store Klout scores
###
cache = new memcache.Client()
cache.on 'error', (error)->
	console.log "Cache client error: #{error}"
	cache = null
.on 'timeout', ()->
	console.log "Cache client did timeout"
.connect()

getFromCache = (key, callback) ->
	return callback 'No cache client set' unless cache
	cache.get key, callback

setInCache = (key, value, lifetime, callback) ->
	return callback 'No cache client set' unless cache
	cache.set key, value, callback, lifetime

###
Klout API
###
getKloutScore = (username, callback) ->
	defaultScoreJson = '{ "kscore": 10 }'
	resource = "http://api.klout.com/1/klout.json?users=#{username}&key=#{config.kloutApi.key}"
	request resource, (error, response, body)->
		unless error or response.statusCode isnt 200
			try
				data = JSON.parse body
				console.log data
				if data.status is 200 and typeof data.users is 'object' and data.users.length
					return callback JSON.stringify(data.users.shift())

			catch e
				error = e			

		# An error happened
		console.log "Error while getting Klout score of '#{username}': #{error}"
		return callback defaultScoreJson

###
Web server
###
require('zappa').run process.env.PORT or config.port, ->
	
	@get '/klout/:username.json', ()->
		@response.header 'Access-Control-Allow-Origin', '*'
		@response.contentType 'application/json'
		
		getFromCache @request.url, (error, data) =>
			return @send data unless error
			getKloutScore @params.username, (jsonString) =>
				@send jsonString
				setInCache @request.url, jsonString, config.cacheTTL, ()->
	
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