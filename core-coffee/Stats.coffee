# provides an interface to register a statistic with a simple label
# `addStat(label)` adds a stat with said label and returns a function
# `update(newVal)` which can be called with udpated values of the stat
# and the displayed statistic will be updated
define [], () ->

  class StatsView extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @render()
      @graphModel = instances["GraphModel"]
      @listenTo @graphModel, "change", @update
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Stats'

    render: ->
      container = $("<div />").addClass("graph-stats-container").appendTo(@$el)
      @$table = $("<table border=\"0\"/>").appendTo(container)
      $("<tr><td class=\"graph-stat-label\">Nodes: </td><td id=\"graph-stat-num-nodes\" class=\"graph-stat\">0</td></tr>").appendTo @$table
      $("<tr><td class=\"graph-stat-label\">Links: </td><td id=\"graph-stat-num-links\" class=\"graph-stat\">0</td></tr>").appendTo @$table
      return this
    update: ->
      @$("#graph-stat-num-nodes").text @graphModel.getNodes().length
      @$("#graph-stat-num-links").text @graphModel.getLinks().length
    addStat: (label) ->
      $label = $("""<td class="graph-stat-label">#{label}: </td>""")
      $stat = $("""<td class="graph-stat"></td>)""")
      $row = $("<tr />").append($label).append($stat)
      @$table.append($row)
      return (newVal) ->
        $stat.text(newVal)
