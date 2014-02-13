# makes nodes "selectable"
define [], () ->

  class Selection extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      @keyListener = instances['KeyListener']
      @graphView = instances['GraphView']
      @linkFilter = @graphView.getLinkFilter()
      @graphModel = instances['GraphModel']

      #Link to keycodes for javascript: http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
      @listenTo @keyListener, "down:17:65", @selectAll                  #CTRL-A
      @listenTo @keyListener, "down:27", @deselectAll                   #ESC
      @listenTo @keyListener, "down:46", @removeSelection               #DEL
      @listenTo @keyListener, "down:13", @removeSelectionCompliment     #ENTR

      # handle selecting and deselecting nodes
      @graphView.on "enter:node:click", (datum) =>
        @toggleSelection datum
      
      @graphView.on "enter:node:dblclick", (datum) =>
        @selectConnectedComponent datum

    renderSelection: () ->
      nodeSelection = @graphView.getNodeSelection()
      if nodeSelection
        nodeSelection.call (selection) ->
          selection.classed "selected", (d) ->
            d.selected

    filterSelection: (filter) ->
      _.each @graphModel.getNodes(), (node) ->
        node.selected = filter(node)

      @renderSelection()

    selectAll: () ->
      @filterSelection (n) ->
        true

      @trigger "change"

    deselectAll: () ->
      @filterSelection (n) ->
        false

      @trigger "change"

    toggleSelection: (node) ->
      node.selected = not node.selected
      @trigger "change"
      @renderSelection()

    removeSelection: () ->
      @graphModel.filterNodes (node) ->
        not node.selected

    removeSelectionCompliment: () ->
      @graphModel.filterNodes (node) ->
        node.selected

    getSelectedNodes: ->
      _.filter @graphModel.getNodes(), (node) ->
        node.selected

    selectBoundedNodes: (dim) ->
      selectRect = {
        left: dim.x
        right: dim.x + dim.width
        top: dim.y
        bottom: dim.y + dim.height
      }

      intersect = (rect1, rect2) ->
        return !(rect1.right < rect2.left || rect1.bottom < rect2.top || rect1.left > rect2.right || rect1.top > rect2.bottom)

      @graphView.getNodeSelection().each (datum, i) ->
        bcr = this.getBoundingClientRect()
        datum.selected = intersect(selectRect, bcr)

      @trigger 'change'
      @renderSelection()

    # select all nodes which have a path to node
    # using links meeting current Connectivity criteria
    selectConnectedComponent: (node) ->

      @nodeHash = @graphModel.get("nodeHash")

      visit = (id) ->
        unless _.has(seen, id)
          seen[id] = 1
          _.each graph[id], (ignore, neighborID) ->
            visit neighborID

      # create adjacency list version of graph
      graph = {}
      lookup = {}
      _.each @graphModel.getNodes(), (node) =>
        graph[@nodeHash(node)] = {}
        lookup[@nodeHash(node)] = node

      _.each @linkFilter.filter(@graphModel.getLinks()), (link) =>
        graph[@nodeHash(link.source)][@nodeHash(link.target)] = 1
        graph[@nodeHash(link.target)][@nodeHash(link.source)] = 1

      # perform DFS to compile connected component
      seen = {}
      visit @nodeHash(node)

      # toggle selection appropriately
      # selection before ==> selection after
      #       none ==> all
      #       some ==> all
      #       all  ==> none
      allTrue = true
      _.each seen, (ignore, id) ->
        allTrue = allTrue and lookup[id].selected

      newSelected = not allTrue
      _.each seen, (ignore, id) ->
        lookup[id].selected = newSelected

      # notify listeners of change
      @trigger "change"

      # update UI
      @renderSelection()
