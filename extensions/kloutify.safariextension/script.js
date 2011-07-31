(function() {
  var Kloutify, kloutify;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Kloutify = (function() {
    Kloutify.prototype.username = null;
    Kloutify.prototype.offset = null;
    Kloutify.prototype.scores = {};
    Kloutify.prototype.timer = null;
    Kloutify.prototype.element = null;
    Kloutify.prototype.config = {
      element_id: 'kloutify',
      score_id: 'kloutify-score',
      timer_value: 600,
      host: 'localhost:5678',
      username_regex: /https?(?::\/\/|%3A%2F%2F)twitter\.com(?:\/|%2F)(?:#!(?:\/|%2F))?([_a-zA-Z0-9]*)(?:&.*)?$/i,
      on_twitter_regex: /^https?:\/\/twitter\.com\//i,
      on_twitter_username_regex: /^(?:https?:\/\/twitter\.com)?(?:\/#!)?\/([_a-zA-Z0-9]*)$/i
    };
    function Kloutify(windowLocation) {
      this.element = $("<div id=\"" + this.config.element_id + "\"><div></div><div id=\"" + this.config.score_id + "\">??</div></div>");
      if (windowLocation.match(this.config.on_twitter_regex)) {
        this.config.username_regex = this.config.on_twitter_username_regex;
      }
    }
    Kloutify.prototype.init = function() {
      return $('body').append(this.element).delegate('a', 'mouseenter', __bind(function(event) {
        return this.mouseentered(event);
      }, this)).delegate('a', 'mouseleave', __bind(function(event) {
        return this.mouseleft(event);
      }, this));
    };
    Kloutify.prototype.extractUsername = function(href) {
      var matches;
      matches = href.match(this.config.username_regex);
      if (matches != null) {
        return matches[1];
      } else {
        return null;
      }
    };
    Kloutify.prototype.mouseentered = function(event) {
      var el, username;
      el = $(event.currentTarget);
      username = this.extractUsername(el.attr('href'));
      if (username != null) {
        return this.timer = setTimeout(__bind(function() {
          return this.update(el, username);
        }, this), this.config.timer_value);
      }
    };
    Kloutify.prototype.mouseleft = function(event) {
      clearTimeout(this.timer);
      return this.hide();
    };
    Kloutify.prototype.hide = function() {
      this.username = null;
      return this.element.offset({
        top: -1000,
        left: -1000
      });
    };
    Kloutify.prototype.update = function(anchor, username) {
      this.username = username;
      this.offset = anchor.offset();
      this.offset.top -= Math.ceil((this.element.outerHeight(true) - anchor.outerHeight(true)) / 2);
      if (this.scores[username] != null) {
        return this.updateScore(username, this.scores[username]);
      } else {
        return $.getJSON("http://" + this.config.host + "/klout/" + this.username + ".json", __bind(function(json) {
          var score;
          score = (json != null ? json.kscore : void 0) != null ? Math.round(json.kscore) : '??';
          return this.updateScore(this.username, score);
        }, this));
      }
    };
    Kloutify.prototype.updateScore = function(username, score) {
      this.scores[username] = score;
      if (username === this.username) {
        $("#" + this.config.score_id).text("K " + score);
        this.offset.left -= this.element.outerWidth(true);
        return this.element.offset(this.offset);
      }
    };
    return Kloutify;
  })();
  kloutify = new Kloutify(window.location.toString());
  $(document).ready(function() {
    return kloutify.init();
  });
}).call(this);
