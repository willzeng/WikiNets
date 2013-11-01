## API

Provides simple statistics about the state of the graph.

Currently, nothing is exposed.

## Code

    define ["core/singleton", "core/workspace"], (Singleton, Workspace) ->

      class GraphStatsView extends Backbone.View

        constructor: (@model) ->
          @model.on "change", @update.bind(this)

        render: ->
          container = $("<div />").addClass("graph-stats-container").appendTo(@$el)
          table = $("<table border=\"0\"/>").appendTo(container)
          $("<tr><td class=\"graph-stat-label\">Nodes: </td><td id=\"graph-stat-num-nodes\" class=\"graph-stat\">0</td></tr>").appendTo table
          $("<tr><td class=\"graph-stat-label\">Links: </td><td id=\"graph-stat-num-links\" class=\"graph-stat\">0</td></tr>").appendTo table
          return this

        update: ->
          @$("#graph-stat-num-nodes").text @model.getNodes().length
          @$("#graph-stat-num-links").text @model.getLinks().length

      class GraphStatsAPI extends Backbone.Model
        constructor: () ->
          model = Workspace.getInstance().getGraphModel()
          graphStatsView = new GraphStatsView(model)

      _.extends GraphStatusAPI, Singleton
