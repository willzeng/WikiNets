# manages overall layout of page
# provides functions to add DOM elements to different locations of the screen
# automatically puts links to celestrium repo in bottom right
# and a button to show/hide all other helpers
define [], () ->

  class Layout extends Backbone.View

    events: "click #bottom-center-outer-container #toggle": "toggle"

    constructor: (@options) ->
      super(@options)
    init: () ->
      @render()
    render: ->
      @tl = $("<div id=\"top-left-container\" class=\"container\"/>")
      @bl = $("<div id=\"bottom-left-container\" class=\"container\"/>")
      @br = $("<div id=\"bottom-right-container\" class=\"container\"/>")
      @tr = $("<div id=\"top-right-container\" class=\"container\"/>")
      @top = $("""<div id="top-center-outer-container" align="center"/>""")
      @bottom = $ """
        <div id="bottom-center-outer-container" align="center">
          <button id="toggle">Show/Hide</button>
        </div>
      """
      @$el.append($el) for $el in [@tl, @bl, @br, @tr, @top, @bottom]
      @addTop($("""<span id="title">#{@options.title}</span>""")) if @options.title?
      @addBottomRight $ """
        <div>
          <a href="https://github.com/jdhenke/celestrium">celestrium repo</a>
        </div>
      """
      return this
    toggle: () ->
      $el.toggle() for $el in [@tl, @bl, @br, @tr, @top]
    addCenter: (el) ->
      @$el.append el
    addTopLeft: (el) ->
      @tl.append el
    addBottomLeft: (el) ->
      @bl.append el
    addTopRight: (el) ->
      @tr.append el
    addBottomRight: (el) ->
      @br.append el
    addTop: (el) ->
      @top.append el
