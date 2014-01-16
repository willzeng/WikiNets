# provides a list of the nodes
define [], () ->

  class ListView extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @graphModel.on "change", @update.bind(this)
      @listenTo instances["KeyListener"], "down:80", () => @$el.toggle() #down on 'p'
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'List View', true

      @data

    update: ->
      @$el.empty()
      allNodes = @graphModel.getNodes()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
      _.each allNodes, (node) ->
        $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        $("<div class=\"node-profile-title\">#{node['text']}</div>").appendTo $nodeDiv
        _.each node, (value, property) ->
          $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0
        $seeNeighbors = $("<input id=\"seeNeighborsButton#{node['_id']}\" type=\"button\" value=\"+\">").appendTo $nodeDiv
