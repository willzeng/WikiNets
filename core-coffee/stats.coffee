define ["core/singleton", "core/graphModel", "core/workspace"], (Singleton, GraphModel, Workspace) ->

  class GraphStatsView extends Backbone.View

    constructor: (@model) ->
      @model.on "change", @update.bind(this)
      super()

    render: ->
      container = $("<div />").addClass("graph-stats-container").appendTo(@$el)
      @$table = $("<table border=\"0\"/>").appendTo(container)
      $("<tr><td class=\"graph-stat-label\">Nodes: </td><td id=\"graph-stat-num-nodes\" class=\"graph-stat\">0</td></tr>").appendTo @$table
      $("<tr><td class=\"graph-stat-label\">Links: </td><td id=\"graph-stat-num-links\" class=\"graph-stat\">0</td></tr>").appendTo @$table
      return this

    update: ->
      @$("#graph-stat-num-nodes").text @model.getNodes().length
      @$("#graph-stat-num-links").text @model.getLinks().length

  class GraphStatsAPI extends Backbone.Model
    constructor: () ->
      model = GraphModel.getInstance()
      @graphStatsView = new GraphStatsView(model).render()
      workspace = Workspace.getInstance()
      workspace.addBottomLeft @graphStatsView.el
    addStat: (label) ->
      $label = $("""<td class="graph-stat-label">#{label}: </td>""")
      $stat = $("""<td class="graph-stat"></td>)""")
      $row = $("<tr />").append($label).append($stat)
      @graphStatsView.$table.append($row)
      return (newVal) ->
        $stat.text(newVal)

  _.extend GraphStatsAPI, Singleton
