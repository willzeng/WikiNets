# uses quick WikiNets syntax to create up a network of nodes and arrows in the database
define [], () ->

  class SyntaxCreate extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      @keyListener = instances['KeyListener']
      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']

      #some key press should take you to the SyntaxCreate box. Perhaps SPACE?
      #@listenTo @keyListener, "down:17:65", @selectAll

      @graphView.on "enter:node:click", @update.bind(this)

      @render()

      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Syntax Create'

    render: ->
      $container = $("<div class=\"syntax-create-container\">").appendTo @$el

      $createNodeButton = $("<input id=\"createNodeButton\" type=\"submit\" value=\"New Node\">").appendTo $container
      $createArrowButton = $("<input id=\"createArrowButton\" type=\"submit\" value=\"New Arrow\">").appendTo $container

      $("<br>").appendTo $container
      $sourceInput = $("<textarea id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo $container

      $arrowInput = $("<textarea id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo $container

      $targetInput = $("<textarea id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo $container

    update: ->
