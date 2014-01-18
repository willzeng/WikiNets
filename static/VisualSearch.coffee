# provides an search box which can add nodes to the graph
# using visualsearch
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
      $container = $("<div />").addClass("visual-search-container")
#      $input = $("<div />").addClass("visual_search")
      $.get "/get_all_node_keys", (data) =>
        @properties = "["+ ("'"+key+"'" for key in data) + "]"
        console.log @properties
        $script = $("""
        <div class="visual_search"></div>
        <script type="text/javascript" charset="utf-8">
          $(document).ready(function() {
            var visualSearch = VS.init({
              container : $('.visual_search'),
              query     : '',
              callbacks : {
                search       : function(query, searchCollection) {},
                facetMatches : function(callback) {callback(#{@properties});},
                valueMatches : function(facet, searchTerm, callback) {}
              }
            });
          });
        </script>
        """).appendTo($container)
      console.log "Rendering Visual Search plugin"

#      $container.append $input
      @$el.append $container

#      $(document).ready(()->
#        visualSearch = VS.init({
#          container : $('.visual_search'),
#          query     : '',
#          callbacks : {
#            search       : (query, searchCollection) -> {},
#            facetMatches : (callback) -> {},
#            valueMatches : (facet, searchTerm, callback) -> {}
#          }
#        })
#      )

      return this

    addNode: (e, datum) ->
      newNode = {text: datum.value, '_id': -1} #TODO FIX THIS BY CHANGING THE NODEHASH FOR WIKINETS
      h = @graphModel.get("nodeHash")
      newNodeHash = h(newNode)
      @graphModel.putNode newNode  unless _.some @graphModel.get("nodes"), (node) ->
        h(node) is newNodeHash
      $(e.target).blur()
