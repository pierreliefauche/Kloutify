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
	
	