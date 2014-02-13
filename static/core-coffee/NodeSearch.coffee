# provides an input box which can add nodes to the graph
define [], () ->

  class NodeSearch extends Backbone.View

    events:
      "typeahead:selected input": "addNode"

    constructor: (@options) ->
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @listenTo instances["KeyListener"], "down:191", (e) =>
        @$("input").focus()
        e.preventDefault()
      @render()
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Search'

    render: ->
      $container = $("<div />").addClass("node-search-container")
      $input = $("<input type=\"text\" placeholder=\"Node Search...\">").addClass("node-search-input")
      $container.append $input
      @$el.append $container
      $input.typeahead
        prefetch: @options.prefetch
        local: @options.local
        name: "nodes"
        limit: 100
      return this

    addNode: (e, datum) ->
      newNode = {text: datum.value, '_id': -1} #TODO FIX THIS BY CHANGING THE NODEHASH FOR WIKINETS
      h = @graphModel.get("nodeHash")
      newNodeHash = h(newNode)
      @graphModel.putNode newNode  unless _.some @graphModel.get("nodes"), (node) ->
        h(node) is newNodeHash
      $(e.target).blur()
