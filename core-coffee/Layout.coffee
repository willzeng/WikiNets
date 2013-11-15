# manages overall layout of page
# provides functions to add DOM elements to different locations of the screen
# automatically puts links to celestrium repo in bottom right
# and a button to show/hide all other helpers
define [], () ->
  class PluginWrapper extends Backbone.View
    className: 'plugin-wrapper'
    events:
      'click .plugin-controls .close': 'close'

    close: (e) ->
      console.log 'collapse'

    initialize: (args) ->
      @plugin = args.plugin
      @collapsed = false
      @render()

    render: ->
      @controls = $ """
        <div class=\"plugin-controls\">
          <div class=\"close\">Header</div>
        </div>
      """
      @content = $("<div class=\"plugin-content\"></div>")
      @content.append @plugin


      @$el.append @controls
      @$el.append @content


  class Layout extends Backbone.View

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
      for pluginWrapper in @pluginWrappers
        console.log pluginWrapper.plugin
        @pluginContainer.append pluginWrapper.el

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
