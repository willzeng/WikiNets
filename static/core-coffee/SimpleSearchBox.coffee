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
      $addNode = $("<div id='add-node' class='result-element'><span>Add Node</span><br/><span>Person</span><span>Project</span><span>Theme</span><span>Other</span></div>").appendTo $('#omniBox')

      #choose which keys will be searched by the fultext search.
      #we initially set this to all keys
      @searchableKeys = {}
      $.get "/get_all_node_keys", (keys) =>
        @searchableKeys = keys

    render: ->

      #build HTML elements
      $container = $("<div id='visual-search-container'>").appendTo @$el
      $searchBox = $('<input type="text" id="searchBox" data-intro="Search the graph" data-position="right" placeholder="Search or Add Node">"')
        .appendTo $container
      $button = $("<div id='goButton'><i class='fa fa-search'></i></div>").appendTo $container



      #call search functionality with press of ENTER key
      $searchBox.keyup (e)=>
        if(e.keyCode == 13)
          @searchNodesSimple $searchBox.val()
          $searchBox.val("")

      #call search functionality with input text
      $button.click () =>
        @searchNodesSimple $searchBox.val()
        $searchBox.val("")

    searchNodesSimple: (searchQuery) =>
      $.post "/node_index_search", {checkKeys: @searchableKeys, query: searchQuery}, (nodes) =>
        if nodes.length < 1 then alert "No Results Found"
        for node in nodes
          @graphModel.putNode(node)
          #selects all the nodes added to the workspace
          modelNode = theNode for theNode in @graphModel.getNodes() when theNode['_id'] is node['_id']
          @selection.selectNode(modelNode)
          
