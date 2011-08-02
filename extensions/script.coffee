class Kloutify
	
	username: null
	offset: null
	scores: {}
	timer: null
	element: null
	config: 
		element_id: 'kloutify'
		score_id: 'kloutify-score'
		timer_value: 600
		host: 'kloutify.com'
		username_regex: /https?(?::\/\/|%3A%2F%2F)(?:www(?:\.|%2E))?twitter(?:\.|%2E)com(?:\/|%2F)(?:#!(?:\/|%2F))?([_a-zA-Z0-9]*)(?:&.*)?$/i
		on_twitter_regex: /^https?:\/\/(?:[^\/]*)?twitter\.com\//i
		on_twitter_username_regex: /^(?:https?:\/\/(?:www(?:\.|%2E))?twitter(?:\.|%2E)com)?(?:\/#!)?\/([_a-zA-Z0-9]*)$/i
		on_twitter_platform: no
		on_twitter_platform_regex: /^https?:\/\/platform\.twitter\.com\//i

	constructor: (windowLocation)->
		@element = $ "<div id=\"#{@config.element_id}\"><div></div><div id=\"#{@config.score_id}\">??</div></div>"
		if windowLocation.match @config.on_twitter_regex
			@config.username_regex = @config.on_twitter_username_regex
			@config.on_twitter_platform = yes if windowLocation.match @config.on_twitter_platform_regex
		
	init: ->
		$('body').append(@element)
		.delegate 'a', 'mouseenter', (event) =>
			@mouseentered event
		.delegate 'a', 'mouseleave', (event) =>
			@mouseleft event
			
	extractUsername: (anchor) ->
		regex = @config.username_regex
		text = anchor.attr('href')
		
		if @config.on_twitter_platform
			if 'follow-button' is anchor.attr 'id'
				text = anchor.attr 'title'
				regex = /@([_a-zA-Z0-9]*)/i
			else if anchor.hasClass 'nickname'
				text = anchor.text()
				regex = /^(.*)$/i
		
		matches = text.match regex
		if matches? then matches[1] else null
		
	mouseentered: (event) ->
		el = $ event.currentTarget
		username = @extractUsername el
		@timer = setTimeout =>
			@update el, username
		, @config.timer_value if username?
	
	mouseleft: (event) ->
		clearTimeout @timer
		@hide()
	
	hide: ->
		@username = null
		@element.offset top: -1000, left: -1000
		
	update: (anchor, username) ->
		@username = username
		@offset = anchor.offset()
		@offset.top -= Math.ceil (@element.outerHeight(yes) - anchor.outerHeight(yes)) / 2
		
		if @scores[username]?
			@updateScore username, @scores[username]
		else
			$.getJSON "http://#{@config.host}/klout/#{@username}.json", (json) =>
				score = if json?.kscore? then Math.round(json.kscore) else '??' 
				@updateScore @username, score
	
	updateScore: (username, score) ->
		@scores[username] = score
		if username is @username
			$("##{@config.score_id}").text "K #{score}"
			@offset.left -= @element.outerWidth yes
			@element.offset @offset


kloutify = new Kloutify(window.location.toString())
$(document).ready ->
	kloutify.init()