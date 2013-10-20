define(['jquery', 'underscore', 'backbone'], function($, _, Backbone) {

  function KeyListener(target) {

    _.extend(this, Backbone.Events);

    var state = {};
    var watch = [17, 65, 27, 46, 13, 16, 80, 187, 191];

    $(window).keydown(function(e) {

      // this ignores keypresses from inputs
      if (e.target !== target || !_.contains(watch, e.which)) return;

      state[e.which] = e;

      var keysDown = _.chain(state)
        .map(function(event, which) {
          return which;
        }).sortBy(function(which) {
          return which;
        }).value();

      var eventName = "down:" + keysDown.join(":");
      this.trigger(eventName, e);
      if (e.isDefaultPrevented()) {
        delete state[e.which];
      }

    }.bind(this)).keyup(function(e) {

      // this ignores keypresses from inputs
      if (e.target !== target) return;

      delete state[e.which];

    }.bind(this));

  };

  return KeyListener;

});