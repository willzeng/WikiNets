# provides a search box which can add nodes to the graph
# using VisualSearch
define [], () ->

  class SimpleSearchBox extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @selection = instances["NodeSelection"]
      @listenTo instances["KeyListener"], "down:191", (e) =>
        @$("input").focus()
        e.preventDefault()
      @render()
      
      $(@el).attr('id','vsplug').appendTo $('#omniBox')
      

      @searchableKeys = {}
      $.get "/get_all_node_keys", (keys) =>
        @searchableKeys = keys

    render: ->
      $container = $("<div id=\"visual-search-container\" style='padding-top:2px'/>").appendTo @$el
      $input = $("<div class=\"visual_search\" />").appendTo $container

      $searchBox = $('<input type="text">').css("width", "220px").css("height", "25px").appendTo $container

      $button = $("<input type=\"button\" value=\"Go\" style='float:right' />").appendTo $container

      $button.click(() =>
        #console.log @searchQuery
        @searchNodesSimple $searchBox.val()
        )

    searchNodesSimple: (searchQuery) =>
      $.post "/node_index_search", {checkKeys: @searchableKeys, query: searchQuery}, (nodes) =>
        console.log nodes
        for node in nodes
          @graphModel.putNode(node)

    searchNodes: (searchQuery) =>
      $.post "/search_nodes", searchQuery, (nodes) =>
        for node in nodes
          @graphModel.putNode(node)
          #@selection.toggleSelection(node)
