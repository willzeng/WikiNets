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
      $.get "/get_all_node_keys", (data) =>
        @keys = data
        console.log @keys
        $(document).ready(() =>
          visualSearch = VS.init({
            container : $('.visual_search')
            query     : ''
            callbacks :
              search       : (query, searchCollection) -> {}
              facetMatches : (callback) => callback @keys
              valueMatches : (facet, searchTerm, callback) -> {}
          })
          #console.log "Initializing Search Box"
        )
        return data
      #console.log "Rendering Visual Search plugin"
      return this

    addNode: (e, datum) ->
      newNode = {text: datum.value, '_id': -1} #TODO FIX THIS BY CHANGING THE NODEHASH FOR WIKINETS
      h = @graphModel.get("nodeHash")
      newNodeHash = h(newNode)
      @graphModel.putNode newNode  unless _.some @graphModel.get("nodes"), (node) ->
        h(node) is newNodeHash
      $(e.target).blur()
