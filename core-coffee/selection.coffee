define ["jquery", "backbone", "d3"], ($, Backbone, d3) ->
  Selection = (graphModel, graphView, linkFilter) ->
    _.extend this, Backbone.Events

    # handle selecting and deselecting nodes
    clickSemaphore = 0
    graphView.on "enter:node", (nodeEnterSelection) =>
      nodeEnterSelection.on("click", (datum, index) =>
        # ignore drag
        return  if d3.event.defaultPrevented
        datum.fixed = true
        clickSemaphore += 1
        savedClickSemaphore = clickSemaphore
        setTimeout (=>
          if clickSemaphore is savedClickSemaphore
            @toggleSelection datum
            datum.fixed = false
          else
            # increment so second click isn't registered as a click
            clickSemaphore += 1
            datum.fixed = false
        ), 250
      ).on "dblclick", (datum, index) =>
        @selectConnectedComponent datum

    @renderSelection = ->
      nodeSelection = graphView.getNodeSelection()
      if nodeSelection
        nodeSelection.call (selection) ->
          selection.classed "selected", (d) ->
            d.selected



    @filterSelection = (filter) ->
      _.each graphModel.getNodes(), (node) ->
        node.selected = filter(node)

      @renderSelection()

    @selectAll = ->
      @filterSelection (n) ->
        true

      @trigger "change"

    @deselectAll = ->
      @filterSelection (n) ->
        false

      @trigger "change"

    @toggleSelection = (node) ->
      node.selected = not node.selected
      @trigger "change"
      @renderSelection()

    @removeSelection = ->
      graphModel.filterNodes (node) ->
        not node.selected


    @removeSelectionCompliment = ->
      graphModel.filterNodes (node) ->
        node.selected


    @getSelectedNodes = ->
      _.filter graphModel.getNodes(), (node) ->
        node.selected



    # select all nodes which have a path to node
    # using links meeting current Connectivity criteria
    @selectConnectedComponent = (node) ->

      visit = (text) ->
        unless _.has(seen, text)
          seen[text] = 1
          _.each graph[text], (ignore, neighborText) ->
            visit neighborText

      # create adjacency list version of graph
      graph = {}
      lookup = {}
      _.each graphModel.getNodes(), (node) ->
        graph[node.text] = {}
        lookup[node.text] = node

      _.each linkFilter.filter(graphModel.getLinks()), (link) ->
        graph[link.source.text][link.target.text] = 1
        graph[link.target.text][link.source.text] = 1

      # perform DFS to compile connected component
      seen = {}
      visit node.text

      # toggle selection appropriately
      # selection before ==> selection after
      #       none ==> all
      #       some ==> all
      #       all  ==> none
      allTrue = true
      _.each seen, (ignore, text) ->
        allTrue = allTrue and lookup[text].selected

      newSelected = not allTrue
      _.each seen, (ignore, text) ->
        lookup[text].selected = newSelected


      # update UI
      @renderSelection()
    return
  Selection
