using 'http'

get '/update/:username.json', ->
	username = @username
	response.contentType ' application/javascript'
	# get score from Klout
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
			score = if data.length > 0 then Math.round JSON.parse(data).users[0].kscore else '??'
			response.send "window.updateKloutifyScore('#{username}', #{score})"
	.end()
	