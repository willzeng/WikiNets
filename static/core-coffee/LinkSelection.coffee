# makes links "selectable"
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
      # just adding shift to all of these may be suboptimal,
      # but we can always come up with new exciting key combinations later
      @listenTo @keyListener, "down:16:17:65", @selectAll                  #CTRL-SHIFT-A
      @listenTo @keyListener, "down:16:27", @deselectAll                   #ESC-SHIFT
      @listenTo @keyListener, "down:16:46", @removeSelection               #DEL-SHIFT
      @listenTo @keyListener, "down:16:13", @removeSelectionCompliment     #ENTR-SHIFT

      # handle selecting and deselecting nodes
      @graphView.on "enter:link:click", (datum) =>
        @toggleSelection datum
      
      #@graphView.on "enter:link:dblclick", (datum) =>
      #  @selectConnectedComponent datum

    renderSelection: () ->
      linkSelection = @graphView.getLinkSelection()
      if linkSelection
        linkSelection.call (selection) ->
          selection.classed "selected", (d) ->
            d.selected

    filterSelection: (filter) ->
      _.each @graphModel.getLinks(), (link) ->
        link.selected = filter(link)

      @renderSelection()

    selectAll: () ->
      @filterSelection (n) ->
        true

      @trigger "change"

    deselectAll: () ->
      @filterSelection (n) ->
        false

      @trigger "change"

    toggleSelection: (link) ->
      link.selected = not link.selected
      @trigger "change"
      @renderSelection()

    removeSelection: () ->
      @graphModel.filterLinks (link) ->
        not link.selected

    removeSelectionCompliment: () ->
      @graphModel.filterLinks (link) ->
        link.selected

    getSelectedLinks: ->
      _.filter @graphModel.getLinks(), (link) ->
        link.selected
