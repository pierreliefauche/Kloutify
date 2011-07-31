jQuery(document).ready(function(){

	var kloutifyAnchor = null
	var kloutifyUsername = null;
	var kloutifyOffset = null;
	var kloutifyScores = {};
	var kloutifyTimer = null;
	
	var kloutify = jQuery('<div id="kloutify"><div></div><div id="kloutify-score">K 34</div></div>');
	jQuery('body').append(kloutify);
	
	var updateKloutify = function(anchor, username) {
		kloutifyUsername = username;
		
		kloutifyOffset = anchor.offset();
		kloutifyOffset.top -= Math.ceil((kloutify.outerHeight(true) - anchor.outerHeight(true))/2);
		
		if (kloutifyScores[username]) {
			window.updateKloutifyScore(username, kloutifyScores[username]);
		}
		else {
			jQuery.getJSON("http://kloutify.drkbrd.com/update/"+username+".json?jsoncallback=?");
		}
	}
	
	window.updateKloutifyScore = function(username, score) {
		kloutifyScores[username] = score;
		
		if (username == kloutifyUsername) {
			jQuery('#kloutify-score').text(score);
			kloutifyOffset.left -= kloutify.outerWidth(true);
			kloutify.offset(kloutifyOffset);
		}
	}
	
	var hideKloutify = function() {
		kloutifyUsername = null;
		kloutify.offset({top: -1000, left: -1000});
	}
	
	jQuery('body').delegate("a.twitter-atreply, a.user-profile-link.", "mouseenter", function(event){
		var el = jQuery(event.currentTarget);
		var href = el.attr('href');
		var username = href.substr(href.lastIndexOf('/')+1);
		kloutifyTimer = setTimeout(function(){
			updateKloutify(el, username);
		}, 600);
	})
	.delegate("a.twitter-atreply, a.user-profile-link", "mouseleave", function(event){
		clearTimeout(kloutifyTimer);
		hideKloutify();
	});
	
});