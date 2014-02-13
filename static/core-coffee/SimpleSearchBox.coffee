# provides a search box which can add nodes to the graph
# using fulltext search of keys and values of nodes
define [], () ->

  class SimpleSearchBox extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      #plugin dependencies
      @graphModel = instances["GraphModel"]
      @selection = instances["NodeSelection"]

      #The '/' key focuses on the search box
      @listenTo instances["KeyListener"], "down:191", (e) =>
        @$("#searchBox").focus()
        e.preventDefault()
      
      @render()
      
      #identify the plugin and place it in the omniBox
      $(@el).attr('id','ssplug').appendTo $('#omniBox')

      #choose which keys will be searched by the fultext search.
      #we initially set this to all keys
      @searchableKeys = {}
      $.get "/get_all_node_keys", (keys) =>
        @searchableKeys = keys

    render: ->

      #build HTML elements
      $container = $("<div id=\"visual-search-container\" style='padding-top:2px'/>").appendTo @$el
      $searchBox = $('<input type="text" id="searchBox">').css("width", "220px").css("height", "25px").appendTo $container
      $button = $("<input type=\"button\" value=\"Go\" style='float:right' />").appendTo $container

      #call search functionality with input text
      $button.click(() =>
        @searchNodesSimple $searchBox.val()
        )

    searchNodesSimple: (searchQuery) =>
      $.post "/node_index_search", {checkKeys: @searchableKeys, query: searchQuery}, (nodes) =>
        for node in nodes
          @graphModel.putNode(node)
          #selects all the nodes added to the workspace
          @selection.toggleSelection(node)
          
