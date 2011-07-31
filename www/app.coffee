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
		.on 'end', =>
			score = if data.length > 0 then Math.round JSON.parse(data).users[0].kscore else "'??'"
			callback? score
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

get '/update/:username.json', ->
	urlKey = "Kloutify/update/#{@username}.json"
	username = @username
	response.contentType ' application/javascript'
	getFromCache urlKey, (json) =>
		if json?
			response.send json
		else
			getKloutScore username, (score) ->
				json = "window.updateKloutifyScore('#{username}', #{score})"
				response.send json
				setInCache urlKey, json, 60*60*24, (didIt) -> {}
	
get '/', ->
	render 'index'
	
get '*', ->
	redirect '/'
	
view index: ->
	div id: 'container', ->
		h1 'Kloutify'
		h2 ->
			a href: 'http://klout.com', onclick: "_gaq.push(['_trackEvent', 'External', 'Visit', 'Klout']);", target:'_blank', 'Klout'
			text ' scores right inside '
			a href: 'http://twitter.com', onclick: "_gaq.push(['_trackEvent', 'External', 'Visit', 'Twitter']);", target:'_blank', 'Twitter.com'
		img alt: 'Screenshot of Kloutify used on Twitter.com', src: '/newsycombinator.png'
		img alt: 'Screenshot of Kloutify used on Twitter.com', class: 'last', src: '/techcrunch.png'
		p class:'install', ->
			text 'Install extension for '
			a href: '/kloutify.crx', class:'download', target:'_blank', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Chrome']);", 'Chrome'
			text ' or '
			a href: '/kloutify.safariextz', class:'download', onclick: "_gaq.push(['_trackEvent', 'Extension', 'Download', 'Safari']);", target:'_blank', 'Safari'
		p class: 'profile', ->
			text 'Browser extensions by '
			a href: 'http://twitter.com/pierreliefauche', class: 'user-profile-link', onclick: "_gaq.push(['_trackEvent', 'Profile', 'Visit', 'pierreliefauche']);", target:'_blank', '@pierreliefauche'
		p class: 'profile',->
			text 'requested by '
			a href: 'http://twitter.com/mortazakarimi', class: 'user-profile-link', onclick: "_gaq.push(['_trackEvent', 'Profile', 'Visit', 'mortazakarimi']);", target:'_blank', '@mortazakarimi'
	
layout ->
	doctype 5
	html ->
		head ->
			meta charset: 'utf-8'
			title 'Kloutify | Klout scores right inside Twitter.com'
			meta name:'description', content:'Kloutify is a browser extension displaying Klout scores on Twitter.com when hovering a username'
			# base href: 'http://kloutify.com/'
			link rel: 'icon', type: 'image/x-icon', href: '/favicon.ico'
			link rel: 'shortcut icon', type: 'image/x-icon', href: '/favicon.ico'
			link rel: 'stylesheet', href: '/app.css'
			link rel: 'stylesheet', href: 'http://kloutify.com/extension/kloutify.css'
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
			# script type: 'text/javascript', 'var addthis_config = {"data_track_clickback":true};'
			# script type: 'text/javascript', src: 'http://s7.addthis.com/js/250/addthis_widget.js#pubid=ra-4e21ac6c0f0647ee'
			script type: 'text/javascript', src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.6.2/jquery.min.js'
			script type: 'text/javascript', src: 'http://kloutify.com/extension/kloutify.js'
		body -> @content