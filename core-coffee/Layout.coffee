# manages overall layout of page
# provides functions to add DOM elements to different locations of the screen
# automatically puts links to celestrium repo in bottom right
# and a button to show/hide all other helpers
define [], () ->
  class PluginWrapper extends Backbone.View
    className: 'plugin-wrapper'
    initialize: (args) ->
      @plugin = args.plugin
      @render()

    render: ->
      @content = $("<div class=\"plugin-content\"></div>")
      @content.append @plugin
      @controls = $("<div class=\"plugin-controls\">x</div>")
      @$el.append @content
      @$el.append @controls


  class Layout extends Backbone.View

    # events: "click #bottom-center-outer-container #toggle": "toggle"

    constructor: (@options) ->
      super(@options)
    init: () ->
      @pluginWrappers = []

      # TODO: find somewhere to put these
      # @bottom = $("<div class=\"plugin-view\" id=\"bottom-center-outer-container\"><button id=\"toggle\">Show/Hide</button></div>")
      # @bottomWrapper = new PluginWrapper(
      #   plugin: @bottom
      #   )
      # @bottomRight = $("<div class=\"plugin-view\"><a href=\"https://github.com/jdhenke/celestrium\">celestrium repo</a></div>")
      # @bottomRightWrapper = new PluginWrapper(
      #   plugin: @bottomRight
      #   )
      # @pluginWrappers.push @bottomWrapper
      # @pluginWrappers.push @bottomRightWrapper

      @render()
    render: ->
      @pluginContainer = $("<div class=\"plugin-container\"/>")
      @$el.append @pluginContainer
      return this

    renderPlugins: ->
      # i feel like i should empty these... but then things break
      # @pluginContainer.empty()
      for pluginWrapper in @pluginWrappers
        console.log pluginWrapper.plugin
        @pluginContainer.append pluginWrapper.el
    # toggle: () ->
    #   $el.toggle() for $el in [@tl, @bl, @br, @tr, @top]

    addCenter: (el) ->
      @$el.append el

    addPlugin: (plugin) ->
      pluginWrapper = new PluginWrapper(
        plugin: plugin
        )
      @pluginWrappers.push pluginWrapper
      @renderPlugins()

    addTopLeft: (el) ->
      @addPlugin el
    addBottomLeft: (el) ->
      @addPlugin el
    addTopRight: (el) ->
      @addPlugin el
    addBottomRight: (el) ->
      @addPlugin el
    addTop: (el) ->
      @addPlugin el
