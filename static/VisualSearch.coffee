# provides a search box which can add nodes to the graph
# using VisualSearch
define [], () ->

  class VisualSearchBox extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @selection = instances["NodeSelection"]
      @listenTo instances["KeyListener"], "down:191", (e) =>
        @$("input").focus()
        e.preventDefault()
      @render()
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Visual Search', true

    render: ->
      $container = $("<div id=\"visual-search-container\"/>").appendTo @$el
      $input = $("<div class=\"visual_search\" />").appendTo $container
      $button = $("<input type=\"button\" value=\"Go!\" />").appendTo $container
      @searchQuery = {}
      $button.click(() =>
        #console.log @searchQuery
        @searchNodes @searchQuery
        )
      $.get "/get_all_node_keys", (data) =>
        @keys = data
        #console.log @keys
        $(document).ready(() =>
          visualSearch = VS.init({
            container : $('.visual_search')
            query     : ''
            callbacks :
              search       : (query, searchCollection) =>
                @searchQuery = {}
                @searchQuery[facet] = searchCollection.find(facet) for facet in @keys when (searchCollection.count(facet)!=0)
              facetMatches : (callback) =>
                $.get "/get_all_node_keys", (data) =>
                  @keys = data
                  callback data
              valueMatches : (facet, searchTerm, callback) =>
                $.post "/get_all_key_values", {property: facet}, (data) -> callback data
          })
        )
        return data
      return this

    searchNodes: (searchQuery) =>
      $.post "/search_nodes", searchQuery, (nodes) =>
        for node in nodes
          @graphModel.putNode(node)
          @selection.toggleSelection(node)

