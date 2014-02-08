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
      #instances["Layout"].addPlugin @el, @options.pluginOrder, 'Visual Search', true
      $(@el).attr('id','vsplug').appendTo $('#buildbar')
      console.log x=@el

    render: ->
      $container = $("<div id=\"visual-search-container\" style='padding-top:2px'/>").appendTo @$el
      $input = $("<div class=\"visual_search\" />").appendTo $container
      $button = $("<input type=\"button\" value=\"Go\" style='float:left' />").appendTo $container
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
                searchCollection.each((term) => @searchQuery[term.attributes.category] = term.attributes.value)
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

