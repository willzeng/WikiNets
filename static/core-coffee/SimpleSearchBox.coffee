# provides a search box which can add nodes to the graph
# using fulltext search of keys and values of nodes
# and typeahead to autocomplete the search
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
      $(@el).attr('id','ssplug').prependTo $('#omniBox')

      #choose which keys will be searched by the fultext search.
      #we initially set this to all keys
      @searchableKeys = {}
      $.get "/get_all_node_keys", (keys) =>
        @searchableKeys = keys

    render: ->

      #build HTML elements
      $container = $("<div id='visual-search-container'>")
      $searchBox = $('<input type="text" class="typeahead" autocomplete="off" id="searchBox" data-intro="Search the graph" data-position="right" placeholder="Search or Add Node">"')
        .appendTo $container
      $button = $("<div id='goButton'><i class='fa fa-search'></i></div>")
        .appendTo $container

      @$el.append $container

      sugg = new Bloodhound({
          datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace(d.name); ,
          queryTokenizer: Bloodhound.tokenizers.whitespace,
          # remote: '../data/sugg/queries/%QUERY.json',
          prefetch: '../node_index_search_prefetch'
        });

        sugg.initialize();

      $searchBox.typeahead(null, {
        displayKey: 'name',
        source: sugg.ttAdapter(),
        templates: {
          suggestion: Handlebars.compile(
            '<p><strong>{{name}}</strong></p>'
          )
        }
        })

      #call search functionality with press of ENTER key
      $searchBox.keyup (e)=>
        if(e.keyCode == 13) # enter key
          @searchNodesSimple $('#searchBox').val()
          $('#searchBox').typeahead('val','')

      #call search functionality with input text
      $button.click () =>
        @searchNodesSimple $('#searchBox').val()
        $('#searchBox').typeahead('val','')

    searchNodesSimple: (searchQuery) =>
      $.post "/node_index_search", {checkKeys: @searchableKeys, query: searchQuery}, (nodes) =>
        if nodes.length < 1 then alert "No Results Found"
        for node in nodes
          @graphModel.putNode(node)
          #selects all the nodes added to the workspace
          modelNode = theNode for theNode in @graphModel.getNodes() when theNode['_id'] is node['_id']
          @selection.selectNode(modelNode)
          
