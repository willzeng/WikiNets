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
      @selection = instances["NodeSelection"]
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Explorations', true

    render: ->
      container = $("<div />").addClass("show-all-container").appendTo(@$el)

      $showAllButton = $("<input type=\"button\" id=\"showAllButton\" value=\"Show All\"></input>").appendTo container
      $showAllButton.click(() =>
        @dataProvider.getEverything(@loadAllNodes)
        )

      $clearAllButton = $("<input type=\"button\" id=\"clearAllButton\" value=\"Clear All\"></input>").appendTo container
      $clearAllButton.click(() =>
        @graphModel.filterNodes (node) -> false
        )

      $selectAllButton = $("<input type=\"button\" id=\"selectAllButton\" value=\"Select All\"></input>").appendTo container
      $selectAllButton.click(() =>
        @selection.selectAll()
        )

      $deselectAllButton = $("<input type=\"button\" id=\"deselectAllButton\" value=\"Deselect All\"></input>").appendTo container
      $deselectAllButton.click(() =>
        @selection.deselectAll()
        )

      $clearSelectedButton = $("<input type=\"button\" id=\"clearSelectedButton\" value=\"Clear Selection\"></input>").appendTo container
      $clearSelectedButton.click(() =>
        @selection.removeSelection()
        )

      $chooseSelectButton = $("<input type=\"button\" id=\"chooseSelectButton\" value=\"Choose Selection\"></input>").appendTo container
      $chooseSelectButton.click(() =>
        @selection.removeSelectionCompliment()
        )

    loadAllNodes: (nodes) =>
      @graphModel.putNode node for node in nodes
