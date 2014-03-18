# provides a search box which can add nodes to the graph
# using VisualSearch
define [], () ->

  class VisualSearchBox extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @selection = instances["NodeSelection"]

      # On the '/' key focus on the search bar
      @listenTo instances["KeyListener"], "down:191", (e) =>
        # why are we doing this.input, what is that even getting?
        @$("input").focus()
        e.preventDefault()

      @render()
      $(@el).attr('id','vsplug')
        .prependTo($('#omniBox'))
        .hide()

      @keys = ['search']

    render: ->

      container = $("<div id='visual-search-container' class='search-box' />").appendTo @el
      input = $("<div class='visual_search' />").appendTo container
      button = $("<input type='button' value='Go' class='left' />").appendTo container

      # TODO: get rid of this, there should only be one search
      switchSearch = $("<input type='button' value='Advanced Search' id='search-switch'/>").appendTo $('#omniBox')

      @searchQuery = {}

      button.click () =>
        @searchDatabase @searchQuery

      # TODO: get rid of this
      switchSearch.click () =>
        if $('#vsplug').is(':visible')
          $('#vsplug').hide()
          $('#ssplug').show()
          switchSearch.val("Advanced Search")
        else
          $('#ssplug').hide()
          $('#vsplug').show()
          switchSearch.val("Simple Search")

      # not sure why we still need this outer search query, but it won't work otherwise
      $.get "/get_all_node_keys", (data) =>
        @keys = data
        # TODO: What does this do?
        $(document).ready(() =>
          visualSearch = VS.init({
            container : $('.visual_search')
            query     : ''
            callbacks :
              search       : (query, searchCollection) =>
                # parse the search query
                @searchQuery = {}
                searchCollection.each((term) => @searchQuery[term.attributes.category] = term.attributes.value)
              facetMatches : (callback) =>
                # this finds a new facet for the search
                # if the searchBox is currently empty, the user is prompted to decide whether to search nodes or links
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
                # this finds the values for the given facet
                # this will break if a node or link has the property "search"
                # -- have put it into list of reserved terms in Neo4jDataController
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
      if _.size(searchQuery) == 0
        # i.e. the searchBox is empty
        alert "Please enter a search query."
      else if searchQuery['search'] == 'nodes'
        if _.size(searchQuery) == 1
          # i.e. the searchBox contains only the term 'search: "nodes"'
          alert "Please enter a further search query for nodes."
        else
          delete searchQuery['search']
          $.post "/search_nodes", searchQuery, (nodes) =>
            for node in nodes
              @graphModel.putNode(node)
              #@selection.toggleSelection(node)
      else
        if  _.size(searchQuery) == 1
          # i.e. the searchBox contains only the term 'search: "links"'
          alert "Please enter a further search query for links."
        else
          delete searchQuery['search']
          $.post "/search_links", searchQuery, (nodes) =>
            # search_links returns the start & end nodes for all links matching the searchQuery
            for node in nodes
              @graphModel.putNode(node)
