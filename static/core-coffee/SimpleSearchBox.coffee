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
      $addProfileHelper = $('<div class="node-profile-helper"></div>').appendTo $('#omniBox')
      #choose which keys will be searched by the fultext search.
      #we initially set this to all keys
      @searchableKeys = {}
      $.get "/get_all_node_keys", (keys) =>
        @searchableKeys = keys

    render: ->

      #build HTML elements
      # $container = $("<div id='visual-search-container'>").appendTo @$el
      # $searchBox = $('<input type="text" id="searchBox" data-intro="Search the graph" data-position="right" placeholder="Search or Add Node">"')
      #   .appendTo $container
      # $button = $("<div id='goButton'><i class='fa fa-search'></i></div>").appendTo $container

      #build HTML elements
      $container = $("<div id='visual-search-container'>")
      $searchBox = $('<input type="text" id="searchBox" data-intro="Search the graph" data-position="right" placeholder="Search or Add Node">"')
        .appendTo $container
      $button = $("<div id='goButton'><i class='fa fa-search'></i></div>")
        .appendTo $container
      $autofillWrapper = $('<div class="autofillWrapperClass" style="border: 1px solid black; border-top: none;"></div>')
        .appendTo $container
      $autofillWrapper.hide()
      @$el.append $container

      # $container = $("<div />").addClass("node-search-container")
      # $input = $("<input type=\"text\" placeholder=\"Node Search...\">").addClass("node-search-input")
      # $container.append $input
      # @$el.append $container
      # $input.typeahead
      #   prefetch: @options.prefetch
      #   local: @options.local
      #   name: "nodes"
      #   limit: 100
      #return this

      films = new Bloodhound({
        datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace(d.name),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        # remote: '../data/films/queries/%QUERY.json',
        prefetch: '../node_index_search_prefetch'
      });

      films.initialize();
      
      $searchBox.typeahead
        displayKey: 'name'
        source: films.ttAdapter()
        templates:
          suggestion: Handlebars.compile '<p><strong>{{name}}</strong> – {{name}}</p>' 
        
      

      # $(document).on "click", ()->
      #   $autofillWrapper.hide()
      
      # $searchBox.on "click", (e)->
      #   $autofillWrapper.show()
      #   e.stopPropagation()
      #   if($searchBox.val()>0)
      #     $searchBox.show()


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
          
