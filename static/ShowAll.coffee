# adds a "Show All Nodes" button to load the whole database into the graph
# model
define [], () ->

  class ShowAll extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @render()
      @graphModel = instances["GraphModel"]
      @dataProvider = instances["local/WikiNetsDataProvider"]
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'ShowAll', true

    render: ->
      container = $("<div />").addClass("show-all-container").appendTo(@$el)
      $showAllButton = $("<input type=\"button\" value=\"Show All\"></input>").appendTo container
      $showAllButton.click(() =>
        @dataProvider.getEverything(@loadAllNodes)
        )

    loadAllNodes: (nodes) =>
      @graphModel.putNode node for node in nodes
