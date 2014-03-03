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
      $container = $("<div id='visual-search-container'>").appendTo @$el
      $searchBox = $('<input type="text" id="searchBox">')
        .css("width", "235px")
        .css("height", "24px")
        .css("border", "1px solid gray")
        .css("outline","none")
        .css("float","left")
        .css("border-right","0px")
        .css("line-height","16pt")
        .css("font-size","15pt")
        .css("padding","2px")
        .appendTo $container
      $button = $("<input type=\"button\" value=\"Go\" style='float:left' />").appendTo $container

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
          
