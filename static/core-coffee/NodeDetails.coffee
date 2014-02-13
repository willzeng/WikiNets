# provides details of the selected nodes
define [], () ->

  class NodeDetailsView extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)
      @listenTo instances["KeyListener"], "down:80", () => @$el.toggle() #down on 'p'
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Node Details'
      @$el.toggle()

    update: ->
      @$el.empty()
      selectedNodes = @selection.getSelectedNodes()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
      _.each selectedNodes, (node) ->
        $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        $("<div class=\"node-profile-title\">#{node['text']}</div>").appendTo $nodeDiv
        _.each node, (value, property) ->
          $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0
