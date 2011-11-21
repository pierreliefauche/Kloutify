(function() {
  var Kloutify, kloutify;
  Kloutify = (function() {
    Kloutify.prototype.username = null;
    Kloutify.prototype.offset = null;
    Kloutify.prototype.scores = {};
    Kloutify.prototype.timer = null;
    Kloutify.prototype.element = null;
    Kloutify.prototype.config = {
      default_score: '10',
      element_id: 'kloutify',
      score_id: 'kloutify-score',
      timer_value: 600,
      host: 'kloutify.com',
      username_regex: /https?(?::\/\/|%3A%2F%2F)(?:www(?:\.|%2E))?twitter(?:\.|%2E)com(?:\/|%2F)(?:#!(?:\/|%2F))?([_a-zA-Z0-9]*)(?:&.*)?$/i,
      on_twitter_regex: /^https?:\/\/(?:[^\/]*)?twitter\.com\//i,
      on_twitter_username_regex: /^(?:https?:\/\/(?:www(?:\.|%2E))?twitter(?:\.|%2E)com)?(?:\/#!)?\/([_a-zA-Z0-9]*)$/i,
      on_twitter_platform: false,
      on_twitter_platform_regex: /^https?:\/\/platform\.twitter\.com\//i
    };
    function Kloutify(windowLocation) {
      this.element = $('<div/>', {
        id: this.config.element_id
      }).append($('<div/>')).append($('<div/>', {
        id: this.config.score_id,
        text: this.config.default_score
      }));
      if (windowLocation.match(this.config.on_twitter_regex)) {
        this.config.username_regex = this.config.on_twitter_username_regex;
        if (windowLocation.match(this.config.on_twitter_platform_regex)) {
          this.config.on_twitter_platform = true;
        }
      }
    }
    Kloutify.prototype.init = function() {
      var _this = this;
      return $('body').append(this.element).delegate('a', 'mouseenter', function(event) {
        return _this.mouseentered(event);
      }).delegate('a', 'mouseleave', function(event) {
        return _this.mouseleft(event);
      });
    };
    Kloutify.prototype.extractUsername = function(anchor) {
      var matches, regex, text;
      regex = this.config.username_regex;
      text = anchor.attr('href');
      if (this.config.on_twitter_platform) {
        if ('follow-button' === anchor.attr('id')) {
          text = anchor.attr('title');
          regex = /@([_a-zA-Z0-9]*)/i;
        } else if (anchor.hasClass('nickname')) {
          text = anchor.text();
          regex = /^(.*)$/i;
        }
      }
      matches = text.match(regex);
      if (matches != null) {
        return matches[1];
      } else {
        return null;
      }
    };
    Kloutify.prototype.mouseentered = function(event) {
      var el, username;
      var _this = this;
      el = $(event.currentTarget);
      username = this.extractUsername(el);
      if (username != null) {
        return this.timer = setTimeout(function() {
          return _this.update(el, username);
        }, this.config.timer_value);
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
      var _this = this;
      this.username = username;
      this.offset = anchor.offset();
      this.offset.top -= Math.ceil((this.element.outerHeight(true) - anchor.outerHeight(true)) / 2);
      if (this.scores[username] != null) {
        return this.updateScore(username, this.scores[username]);
      } else {
        return $.getJSON("http://" + this.config.host + "/klout/" + this.username + ".json", function(json) {
          var score;
          score = (json != null ? json.kscore : void 0) != null ? Math.round(json.kscore) : _this.config.default_score;
          return _this.updateScore(_this.username, score);
        });
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