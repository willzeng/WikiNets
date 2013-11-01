## API

## Code

    define ["core/graphModel", "core/workspace", "core/Singleton"], (GraphModel, Workspace, Singleton) ->

      class NodeSearch extends Backbone.View

        events:
          "typeahead:selected input": "addNode"

        initialize: (@graphModel, @prefetch) ->

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
          newNode = text: datum.value
          h = @graphModel.get("nodeHash")
          newNodeHash = h(newNode)
          @graphModel.putNode newNode  unless _.some @graphModel.get("nodes"), (node) ->
            h(node) is newNodeHash
          $(e.target).blur()

      class NodeSearchAPI extends Backbone.Model
        constructor: (prefetch) ->
          graphModel = GraphModel.getInstance()
          nodeSearch = new NodeSearch(graphModel, prefetch).render()
          workspace = Workspace.getInstance()
          workspace.addTopRight(workspace)

      _.extends NodeSearchAPI, Singleton
