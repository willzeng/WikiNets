# fires down:key1:key2... with all currently down keys on keydowns
define [], () ->

  class KeyListener

    constructor: (target) ->
      _.extend this, Backbone.Events
      state = {}
      watch = [13, 17, 65, 27, 46, 13, 16, 80, 187, 191]

      # this ignores keypresses from inputs
      $(window).keydown (e) =>
        return  if e.target isnt target or not _.contains(watch, e.which)
        state[e.which] = e
        keysDown = _.chain(state).map((event, which) ->
          which
        ).sortBy((which) ->
          which
        ).value()
        eventName = "down:#{keysDown.join(':')}"
        @trigger eventName, e
        delete state[e.which] if e.isDefaultPrevented()

      # this ignores keypresses from inputs
      $(window).keyup (e) =>
        return if e.target isnt target
        delete state[e.which]

    init: () ->
