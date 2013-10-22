define ["jquery", "jquery.typeahead", "backbone"], ($, ignore, Backbone) ->
    NodeSearch = Backbone.View.extend(
        events:
            "typeahead:selected input": "addNode"

        initialize: (options) ->
            @graphModel = options.graphModel
            @prefetch = options.prefetch

        render: ->
            $container = $("<div />").addClass("node-search-container")
            $input = $("<input type=\"text\" placeholder=\"Node Search...\">").addClass("node-search-input")
            $container.append $input
            @$el.append $container
            $input.typeahead
                prefetch: @prefetch
                name: "nodes"
                limit: 100

            return this

        addNode: (e, datum) ->
            graphModel = @graphModel
            newNode = text: datum.value
            h = graphModel.get("nodeHash")
            newNodeHash = h(newNode)
            graphModel.putNode newNode  unless _.some(graphModel.get("nodes"), (node) ->
                h(node) is newNodeHash
            )
            $(e.target).blur()
    )
    return NodeSearch
