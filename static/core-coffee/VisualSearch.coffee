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
      $(@el).attr('id','vsplug').appendTo $('#omniBox')
      console.log x=@el

      @keys = ['search']

    render: ->
      $container = $("<div id=\"visual-search-container\" style='padding-top:2px'/>").appendTo @$el
      $input = $("<div class=\"visual_search\" />").appendTo $container
      $button = $("<input type=\"button\" value=\"Go\" style='float:left' />").appendTo $container
      @searchQuery = {}
      $button.click(() =>
        #console.log @searchQuery
        @searchDatabase @searchQuery
        )
      $.get "/get_all_keys", (data) =>
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
                if visualSearch.searchBox.value().indexOf('search: "nodes"') > -1
                  $.get "/get_all_node_keys", (data) =>
                    @keys = data
                    callback data
                else if visualSearch.searchBox.value().indexOf('search: "links"') > -1
                  $.get "/get_all_link_keys", (data) =>
                    @keys = data
                    callback data
                else
                  @keys = ['search']
                  callback @keys
              valueMatches : (facet, searchTerm, callback) =>
                # this might break if some link or node has a property "search"
                if facet == 'search'
                  callback ['links', 'nodes']
                else if visualSearch.searchBox.value().indexOf('search: "nodes"') > -1
                  $.post "/get_all_node_key_values", {property: facet}, (data) -> callback data
                else
                  $.post "/get_all_link_key_values", {property: facet}, (data) -> callback data
          })
        )
        return data
      return this

    searchDatabase: (searchQuery) =>
      # should add check to avoid empty searches
      if searchQuery['search'] == 'nodes'
        delete searchQuery['search']
        $.post "/search_nodes", searchQuery, (nodes) =>
          for node in nodes
            @graphModel.putNode(node)
            #@selection.toggleSelection(node)
      else
        delete searchQuery['search']
        $.post "/search_links", searchQuery, (nodes) =>
          # search_links returns the start & end nodes for all links matching the searchQuery
          for node in nodes
            @graphModel.putNode(node)
            #@selection.toggleSelection(node)

