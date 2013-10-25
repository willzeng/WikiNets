# main javascript for page
define ["jquery", "core/graphModel", "core/graphView", "core/nodeSearch", "core/selection", "core/graphStats", "core/forceSliders", "core/linkChecker", "core/keyListener", "core/linkHistogram", "core/nodeProfile"], ($, GraphModel, GraphView, NodeSearch, Selection, GraphStatsView, ForceSlidersView, LinkChecker, KeyListener, LinkHistogramView, NodeProfile) ->
  Workspace = Backbone.View.extend(
    initialize: (options) ->
      nodePrefetch = @nodePrefetch = options.nodePrefetch
      dataProvider = @dataProvider = options.dataProvider

      graphModel = @graphModel = new GraphModel(
        nodeHash: (node) ->
          node.text

        linkHash: (link) ->
          link.source.text + link.target.text

        nodeAttributes: options.nodeAttributes or {}
        linkAttributes: options.linkAttributes or {}
      )

      new LinkChecker(graphModel, dataProvider)

      LinkFilter = Backbone.Model.extend(
        initialize: ->
          @set "threshold", 1
          @set "minThreshold", 0.75
        filter: (links) ->
          return _.filter links, (link) =>
            return link.strength > @get("threshold")
        connectivity: (value) ->
          if value
            @set("threshold", value)
          else
            @get("threshold")
      )
      @linkFilter = new LinkFilter()


      graphView = @graphView = new GraphView(
        model: graphModel
        linkFilter: @linkFilter
      ).render()

      @graphView.listenTo(@linkFilter, "change:threshold", graphView.update)

      @sel = new Selection(graphModel, graphView, @linkFilter)

      # adjust link strength and width based on threshold
      linkStrength = (link) =>
        return (link.strength - @linkFilter.get("threshold")) / (1.0 - @linkFilter.get("threshold"))
      graphView.getForceLayout().linkStrength linkStrength
      updateStrokeWidth = (enterSelection) ->
        enterSelection.attr "stroke-width", (link) ->
          return 5 * linkStrength(link)
      graphView.on "enter:link", updateStrokeWidth
      @linkFilter.on "change:threshold", ->
        updateStrokeWidth graphView.getLinkSelection()


    render: ->
      keyListener = new KeyListener(document.querySelector("body"))
      sel = @sel
      nodeProfile = new NodeProfile(
        selection: sel
      ).render()

      # CTRL + A
      keyListener.on "down:17:65", sel.selectAll, sel

      # ESC
      keyListener.on "down:27", sel.deselectAll, sel

      # p
      keyListener.on "down:80", nodeProfile.toggle, nodeProfile

      # DEL
      keyListener.on "down:46", sel.removeSelection, sel

      # ENTER
      keyListener.on "down:13", sel.removeSelectionCompliment, sel

      # PLUS
      keyListener.on "down:16:187", =>
        @dataProvider.getLinkedNodes sel.getSelectedNodes(), (nodes) =>
          _.each nodes, (node) =>
            @graphModel.putNode node


      # FORWARD_SLASH
      keyListener.on "down:191", (e) ->
        $(".node-search-input").focus()
        e.preventDefault()

      @$el.append @graphView.el
      graphStatsView = new GraphStatsView(
        model: @graphModel
      ).render()

      forceSlidersView = new ForceSlidersView(
        graphView: @graphView
        linkFilter: @linkFilter
      ).render()

      linkHistogramView = new LinkHistogramView(
        model: @graphModel
      ).render()

      tl = $("<div id=\"top-left-container\" class=\"container\"/>")
      tl.append forceSlidersView.el
      tl.append linkHistogramView.el

      bl = $("<div id=\"bottom-left-container\" class=\"container\"/>")
      bl.append graphStatsView.el

      br = $("<div id=\"bottom-right-container\" class=\"container\"/>")
      br.append nodeProfile.el

      @$el.append(tl).append(bl).append br

      if @nodePrefetch
        nodeSearch = new NodeSearch(
          graphModel: @graphModel
          prefetch: @nodePrefetch
        ).render()
        tr = $("<div id=\"top-right-container\" class=\"container\"/>")
        tr.append nodeSearch.el
        @$el.append tr

      return this
    )
  return Workspace
