# provides a search box which can add nodes to the graph
# using VisualSearch
define [], () ->

  class VisualSearchBox extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
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
        @keys = data[0]
        @values = data[1]
        #console.log @keys
        $(document).ready(() =>
          visualSearch = VS.init({
            container : $('.visual_search')
            query     : ''
            callbacks :
              search       : (query, searchCollection) =>
                @searchQuery = {}
                @searchQuery[facet] = searchCollection.find(facet) for facet in @keys when (searchCollection.count(facet)!=0)
              facetMatches : (callback) => callback @keys
              valueMatches : (facet, searchTerm, callback) => callback @values[facet]
          })
        )
        return data
      return this

    searchNodes: (searchQuery) =>
      $.post "/search_nodes", searchQuery, (nodes) => @graphModel.putNode(node) for node in nodes

