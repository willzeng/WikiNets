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
      
      #instances["Layout"].addPlugin @el, @options.pluginOrder, 'Explorations', true
      $(@el).appendTo $('#toolBox')


      @graphView = instances["GraphView"]
      @listView = instances["local/ListView"]

    render: ->
      $container = $("<div id=\"show-all-container\">").appendTo(@$el)

      $listViewButton = $("<input type=\"button\" id=\"listViewButton\" value=\"List View\"></input>").appendTo $container
      $listViewButton.click(() =>
        $(@listView.el).show()
        $(@graphView.el).hide()
        )

      $graphViewButton = $("<input type=\"button\" id=\"graphViewButton\" value=\"Graph View\"></input>").appendTo $container
      $graphViewButton.click(() =>
        $(@listView.el).hide()
        $(@graphView.el).show()
        )

      $showAllButton = $("<input type=\"button\" id=\"showAllButton\" value=\"Show All\"></input>").appendTo $container
      $showAllButton.click(() =>
        @dataProvider.getEverything(@loadAllNodes)
        )

      $clearAllButton = $("<input type=\"button\" id=\"clearAllButton\" value=\"Clear All\"></input>").appendTo $container
      $clearAllButton.click(() =>
        @graphModel.filterNodes (node) -> false
        )

      $expandSelectionButton = $("<input type=\"button\" id=\"expandSelectionButton\" value=\"Expand Selection\"></input>").appendTo $container
      $expandSelectionButton.click(() =>
        @expandSelection()
        )

      $selectAllButton = $("<input type=\"button\" id=\"selectAllButton\" value=\"Select All\"></input>").appendTo $container
      $selectAllButton.click(() =>
        @selection.selectAll()
        )

      $deselectAllButton = $("<input type=\"button\" id=\"deselectAllButton\" value=\"Deselect All\"></input>").appendTo $container
      $deselectAllButton.click(() =>
        @selection.deselectAll()
        )

      $clearSelectedButton = $("<input type=\"button\" id=\"clearSelectedButton\" value=\"Clear Selection\"></input>").appendTo $container
      $clearSelectedButton.click(() =>
        @selection.removeSelection()
        )

      $chooseSelectButton = $("<input type=\"button\" id=\"chooseSelectButton\" value=\"Clear Unselected\"></input>").appendTo $container
      $chooseSelectButton.click(() =>
        @selection.removeSelectionCompliment()
        )

      $unpinAllButton = $("<input type=\"button\" id=\"unpinAllButton\" value=\"Un-pin Layout\"></input>").appendTo $container
      $unpinAllButton.click(() =>
        node.fixed = false for node in @graphModel.getNodes()
        )

      $unpinAllButton = $("<input type=\"button\" id=\"unpinAllButton\" value=\"Pin Layout\"></input>").appendTo $container
      $unpinAllButton.click(() =>
        node.fixed = true for node in @graphModel.getNodes()
        )

      $unpinSelectedButton = $("<input type=\"button\" id=\"unpinSelectedButton\" value=\"Un-Pin Selected\"></input>").appendTo $container
      $unpinSelectedButton.click(() =>
        node.fixed = false for node in @selection.getSelectedNodes()
        )

      $pinSelectedButton = $("<input type=\"button\" id=\"unpinSelectedButton\" value=\"Pin Selected\"></input>").appendTo $container
      $pinSelectedButton.click(() =>
        node.fixed = true for node in @selection.getSelectedNodes()
        )

      $showLearningButton = $("<input type=\"button\" id=\"showLearningButton\" value=\"Learning\"></input>").appendTo $container
      $showLearningButton.click(() =>
        @searchNodes({Theme:"Learning"})
        )

      $showStudentLifeButton = $("<input type=\"button\" id=\"showStudentLifeButton\" value=\"Student Life\"></input>").appendTo $container
      $showStudentLifeButton.click(() =>
        @searchNodes({Theme:"Student Life"})
        )
            
      $showResearchButton = $("<input type=\"button\" id=\"showResearchButton\" value=\"Research\"></input>").appendTo $container
      $showResearchButton.click(() =>
        @searchNodes({Theme:"Research"})
        )

    loadAllNodes: (nodes) =>
      @graphModel.putNode node for node in nodes


    expandSelection: () =>
      @dataProvider.getLinkedNodes @selection.getSelectedNodes(), (nodes) =>
          _.each nodes, (node) =>
            @graphModel.putNode node if @dataProvider.nodeFilter node

    searchNodes: (searchQuery) =>
      $.post "/search_nodes", searchQuery, (nodes) =>
        console.log "made it here: " + searchQuery[0]
        for node in nodes
          @graphModel.putNode(node)
          @selection.toggleSelection(node)
