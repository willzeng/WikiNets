# manages overall layout of page
# provides functions to add DOM elements to different locations of the screen
# automatically puts links to celestrium repo in bottom right
# and a button to show/hide all other helpers
define ["core/singleton"], (Singleton) ->

  class Workspace extends Backbone.View

    events: "click #bottom-center-outer-container #toggle": "toggle"

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

      return this

    toggle: () ->
      $el.toggle() for $el in [@tl, @bl, @br, @tr, @top]

  class WorkspaceAPI extends Backbone.Model
    constructor: (options) ->
      @workspace = new Workspace(options).render()
      @addTop($("""<span id="title">#{options.title}</span>""")) if options.title?
      @addBottomRight $ """
        <div>
          <a href="https://github.com/jdhenke/celestrium">celestrium repo</a>
        </div>
      """
    addCenter: (el) ->
      @workspace.$el.append el
    addTopLeft: (el) ->
      @workspace.tl.append el
    addBottomLeft: (el) ->
      @workspace.bl.append el
    addTopRight: (el) ->
      @workspace.tr.append el
    addBottomRight: (el) ->
      @workspace.br.append el
    addTop: (el) ->
      @workspace.top.append el

  _.extend WorkspaceAPI, Singleton
