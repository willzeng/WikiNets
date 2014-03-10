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
        .css("height", "25px")
        .css("box-shadow", "2px 2px 4px #888888")
        .css("border", "1px solid blue")
        .appendTo $container
      $button = $("<input type=\"button\" value=\"Go\" style='float:right' />").appendTo $container
      $autofillWrapper = $('<div class="autofillWrapperClass" style="border: 1px solid black; border-top: none;"></div>').appendTo $container
      $autofillWrapper.hide()


      films = new Bloodhound({
          datumTokenizer: (d) -> Bloodhound.tokenizers.whitespace(d.name); ,
          queryTokenizer: Bloodhound.tokenizers.whitespace,
          # remote: '../data/films/queries/%QUERY.json',
          prefetch: '../node_index_search_prefetch'
        });

        films.initialize();

        $searchBox.typeahead(null, {
          displayKey: 'value',
          source: films.ttAdapter(),
          templates: {
            suggestion: Handlebars.compile(
              '<p><strong>{{name}}</strong> – {{name}}</p>'
            )
          }
        });


      #call search functionality with press of ENTER key
      # $searchBox.keyup (e)=>
      #   if(e.keyCode == 13)
      #     @searchNodesSimple $searchBox.val()
      #     $searchBox.val("")
      #     $autofillWrapper.empty()
      #     $autofillWrapper.hide()
      #   else if($searchBox.val()!="")
      #     #@searchNodesAutofill $searchBox.val(),$autofillWrapper
      #     $tempquery = $searchBox.val()
      #     $.post "/node_index_search", {checkKeys: @searchableKeys, query: $searchBox.val()}, (nodes) =>
      #       if($tempquery!=$searchBox.val())
      #         return
      #       $autofillWrapper.empty()
      #       for node in nodes
      #         #console.log node
      #         $autofillField = $("<span>" + node.name + "</span><br>").appendTo $autofillWrapper
      #     $autofillWrapper.show()
      #   else if($searchBox.val()=="")
      #     $autofillWrapper.empty()

      $(document).on "click", ()->
        $autofillWrapper.hide()
      $searchBox.on "click", (e)->
        $autofillWrapper.show()
        e.stopPropagation()
        if($searchBox.val()>0)
          $searchBox.show()

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

    # searchNodesAutofill: (searchQuery,autofillWrapper) =>
    #     $.post "/node_index_search", {checkKeys: @searchableKeys, query: searchQuery}, (nodes) =>
    #       $autofillWrapper.empty()
    #       for node in nodes
    #         #console.log node
    #         $autofillField = $("<p>" + node.name + "</p>").appendTo $autofillWrapper
          