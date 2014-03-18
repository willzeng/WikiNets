# provides a search box which can add nodes to the graph
# using fulltext search of keys and values of nodes
define [], () ->

  class SimpleSearchBox extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      #plugin dependencies
      @graphModel = instances["GraphModel"]
      @nodeSelection = instances["NodeSelection"]

      #The '/' key focuses on the search box
      @listenTo instances["KeyListener"], "down:191", (e) =>
        @$("#searchBox").focus()
        e.preventDefault()

      # identify the plugin and place it in the omniBox
      $(@el).attr('id','ssplug').prependTo $('#omniBox')

      #choose which keys will be searched by the fultext search.
      #we initially set this to all keys
      @searchableKeys = {}
      $.get "/get_all_node_keys", (keys) =>
        @searchableKeys = keys

      @render()

    render: ->

      #build HTML elements
      container = $("<div id='visual-search-container'>").appendTo @el
      searchBox = $('<input type="text" id="searchBox">').appendTo container
      button = $("<input type='button' value='Go' class='right' />").appendTo container

      #call search functionality with press of ENTER key
      searchBox.keyup (e)=>
        if(e.keyCode == 13)
          @searchNodesSimple searchBox.val()

      #call search functionality with input text
      button.click () =>
        @searchNodesSimple searchBox.val()

    ###
    Posts to node_index_search
    Looks for the searchQuery in the names of the nodes.
    ###
    searchNodesSimple: (searchQuery) =>
      $.post "/node_index_search", {checkKeys: @searchableKeys, query: searchQuery}, (nodes) =>
        if nodes.length < 1 then alert "No Results Found"
        for node in nodes
          @graphModel.putNode(node)
          #selects all the nodes added to the workspace
          # TODO: make this more inefficient, selecting nodes shouldn't be n^2
          modelNode = theNode for theNode in @graphModel.getNodes() when theNode['_id'] is node['_id']
          @nodeSelection.selectNode(modelNode)
