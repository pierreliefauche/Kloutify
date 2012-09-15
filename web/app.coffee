http = require 'http'
memcache = require 'memcache'
defaultScoreJson = '{ "kscore": 10 }'

config = require './config'

require('zappa').run process.env.PORT or config.port, ->

	@helper getKloutScore: (username, callback) ->
		try
			http.request
				method: 'GET'
				host: 'api.klout.com'
				port: 80
				path: "/1/klout.json?users=#{username}&key=#{config.kloutApi.key}"
			.on 'response', (res) ->
				return callback defaultScoreJson if res.statusCode isnt 200
			
				data = ''
				res.on 'data', (chunk) ->
					data += chunk
				.on 'end', ->
					parsedData = JSON.parse(data)
					return callback defaultScoreJson if parsedData.status isnt 200 or not parsedData.users? or typeof parsedData.users is 'undefined'
					callback if data.length > 0 then JSON.stringify(parsedData.users[0]) else defaultScoreJson
			.end()
		catch error
			console.log "ERROR WHILE GETTING SCORE OF #{username} FROM THE API"
			console.log error

	@helper getFromCache: (key, callback) ->
		try
			client = new memcache.Client()
			client.on 'error', (err) ->
				callback false
			.on 'timeout', () ->
				callback false
			.on 'connect', ()->
				client.get key, (error, result) ->
					client.close()
					result = false if error?
					callback result
			.connect()	
		catch error
			console.log 'ERROR WHILE GETTING SCORE FROM CACHE'
			console.log error

	@helper setInCache: (key, value, lifetime, callback) ->
		try
			client = new memcache.Client()
			client.on 'error', (err) ->
				callback false
			.on 'timeout', () ->
				callback false
			.on 'connect', ()->
				client.set key, value, (error, result) ->
					client.close()
					callback? if error? then false else true
				, lifetime
			.connect()
		catch error
			console.log 'ERROR WHILE SETTING SCORE INTO CACHE'
			console.log error
	
	@get '/klout/:username.json', ->
		urlKey = "/klout/#{@params.username}.json"
		@response.header 'Access-Control-Allow-Origin', '*'
		@response.contentType 'application/json'
		@getFromCache urlKey, (data) =>
			return @send data if data isnt false and data isnt null
			@getKloutScore @params.username, (json) =>
				@send json
				if json isnt 'null' then @setInCache urlKey, json, 60*60*1
	
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
				link rel: 'stylesheet', href: '/app.css'
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