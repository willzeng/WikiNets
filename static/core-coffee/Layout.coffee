# manages overall layout of page
# provides functions to add DOM elements to different locations of the screen
# automatically puts links to celestrium repo in bottom right
# and a button to show/hide all other helpers
define [], () ->
  class PluginWrapper extends Backbone.View
    className: 'plugin-wrapper'

    initialize: (args) ->
      @plugin = args.plugin
      @pluginName = args.name
      @init_state = args.init_state
      if args.init_state? then @collapsed = args.init_state else @collapsed = true
      @render()

    events:
      'click .plugin-controls .header': 'close'

    close: (e) ->
      if @collapsed
        @collapsed = false
        # expand
        @expand @$el.find('.plugin-content')
      else
        @collapsed = true
        # collapse
        @collapse @$el.find('.plugin-content')

    expand: (el) ->
      el.slideDown(300)
      @$el.removeClass('collapsed')

    collapse: (el) ->
      el.slideUp(300)
      @$el.addClass('collapsed')

    render: ->
      @controls = $ """
        <div class=\"plugin-controls\">
          <div class=\"header\">
            <span>#{@pluginName}</span>
            <div class=\"arrow\"></div>
          </div>
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
      # a dictionary of lists, so we can order plugins
      @pluginWrappers = {}

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
      keys = _.keys(@pluginWrappers).sort()
      _.each keys, (key, i) =>
        pluginWrappersList = @pluginWrappers[key]
        _.each pluginWrappersList, (pluginWrapper) =>
          @pluginContainer.append pluginWrapper.el
          if !pluginWrapper.init_state
            pluginWrapper.collapse pluginWrapper.$el.find('.plugin-content')


    addCenter: (el) ->
      @$el.append el


    addPlugin: (plugin, pluginOrder, name="Plugin", defaultView) ->
      pluginOrder ?= Number.MAX_VALUE
      pluginWrapper = new PluginWrapper(
        plugin: plugin
        name: name
        order: pluginOrder
        init_state: defaultView
        )
      if _.has @pluginWrappers, pluginOrder
        @pluginWrappers[pluginOrder].push pluginWrapper
      else
        @pluginWrappers[pluginOrder] = [pluginWrapper]
      @renderPlugins()
