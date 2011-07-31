# port 5340

using 'http'
def memcache: require('./node_modules/memcache')

helper getKloutScore: (username, callback) ->
	http.request
		method: 'GET'
		host: 'api.klout.com'
		port: 80
		path: "/1/klout.json?users=#{username}&key=jgjncb86z9fsw7sbufpu2ysg"
	.on 'response', (res) ->
		data = ''
		res.on 'data', (chunk) ->
			data += chunk
		.on 'end', ->
			callback? if data.length > 0 and JSON.parse(data).status is 200 then JSON.parse(data).users[0] else 'null'
	.end()

helper getFromCache: (key, callback) ->
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

helper setInCache: (key, value, lifetime, callback) ->
	client = new memcache.Client()
	client.on 'error', (err) ->
		callback false
	.on 'timeout', () ->
		callback false
	.on 'connect', ()->
		client.set key, value, (error, result) ->
			client.close()
			callback if error? then false else true
		, lifetime
	.connect()
	
get '/klout/:username.json', ->
	urlKey = "Kloutify/klout/#{@username}.json"
	response.header 'Access-Control-Allow-Origin', '*'
	response.contentType 'application/json'
	getFromCache urlKey, (json) =>
		return response.send json if json isnt false
		getKloutScore @username, (data) ->
			response.send data
			setInCache urlKey, data, 60*60*1, (didIt) -> {}
	
get '/', ->
	render 'index'
	
get '*', ->
	redirect '/'
	
view index: ->
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
			a href: '/extension/kloutify.crx', class:'download', target:'_blank', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Chrome']);", 'Chrome'
			text ' or '
			a href: '/extension/kloutify.safariextz', class:'download', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Safari']);", target:'_blank', 'Safari'
		p class: 'profile', ->
			text 'Browser extensions by '
			a href: 'http://twitter.com/pierreliefauche', class: 'user-profile-link', onclick: "_gaq.push(['_trackEvent', 'Profile', 'Visit', 'pierreliefauche']);", target:'_blank', '@pierreliefauche'
		# p class: 'profile',->
		# 	text 'requested by '
		# 	a href: 'http://twitter.com/mortazakarimi', class: 'user-profile-link', onclick: "_gaq.push(['_trackEvent', 'Profile', 'Visit', 'mortazakarimi']);", target:'_blank', '@mortazakarimi'
		
	
layout ->
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
		body -> @content