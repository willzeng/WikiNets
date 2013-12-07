# uses quick WikiNets syntax to create up a network of nodes and arrows in the database
define [], () ->

  class SyntaxCreate

    init: (instances) ->

      _.extend this, Backbone.Events

      @keyListener = instances['KeyListener']
      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']

      #some trigger should take you to the SyntaxCreate box
      #perhaps SPACE?
      #@listenTo @keyListener, "down:17:65", @selectAll

      @graphView.on "enter:node:click", @update.bind(this)

      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Node Details'

    update: ->
          @$el.empty()
          $container = $("<div class=\"syntax-create-container\"/>").appendTo(@$el)
          blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
          _.each selectedNodes, (node) ->
            $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
            $("<div class=\"node-profile-title\">#{node['text']}</div>").appendTo $nodeDiv
            _.each node, (value, property) ->
              $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0
