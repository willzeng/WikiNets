/* main javascript for page */
define(["jquery", "celestrium/graphModel", "celestrium/graphView", "celestrium/nodeSearch", "celestrium/selection", "celestrium/graphStats", "celestrium/forceSliders", "celestrium/linkChecker", "celestrium/keyListener", "celestrium/linkHistogram"], 
function($, GraphModel, GraphView, NodeSearch, Selection, GraphStatsView, ForceSlidersView, LinkChecker, KeyListener, LinkHistogramView) {

  var Celestrium = Backbone.View.extend({

    initialize: function() {

      var dataProvider = this.options.dataProvider;

      var graphModel = new GraphModel({
        nodeHash: function(node) {
          return node.text;
        },
        linkHash: function(link) {
          return link.source.text + link.target.text;
        },
      });

      var graphView = new GraphView({
        model: graphModel,
      }).render();

      new LinkChecker(graphModel, dataProvider);

      var sel = new Selection(graphModel, graphView);

      var keyListener = new KeyListener(document.querySelector("body"));

      // CTRL + A
      keyListener.on("down:17:65", sel.selectAll, sel);
      // ESC
      keyListener.on("down:27", sel.deselectAll, sel);

      // DEL
      keyListener.on("down:46", sel.removeSelection, sel);
      // ENTER
      keyListener.on("down:13", sel.removeSelectionCompliment, sel);

      // PLUS
      keyListener.on("down:16:187", function() {
        dataProvider.getRelatedNodes(sel.getSelectedNodes(), function(nodes) {
          _.each(nodes, function(node) {
            graphModel.putNode(node);
          });
        });
      });

      // /
      keyListener.on("down:191", function(e) {
        $(".node-search-input").focus();
        e.preventDefault();
      });

      this.$el.append(graphView.el);

      var nodeSearch = new NodeSearch({
        dataProvider: dataProvider,
        graphModel: graphModel,
      }).render();

      var graphStatsView = new GraphStatsView({
        model: graphModel,
      }).render();

      var forceSlidersView = new ForceSlidersView({
        graphView: graphView,
      }).render();

      var linkHistogramView = new LinkHistogramView({
        model: graphModel,
      }).render();

      var tl = $('<div id="top-left-container" class="container"/>');
      tl.append(forceSlidersView.el);
      tl.append(linkHistogramView.el);

      var tr = $('<div id="top-right-container" class="container"/>');
      tr.append(nodeSearch.el);

      var bl = $('<div id="bottom-left-container" class="container"/>');
      bl.append(graphStatsView.el);

      this.$el
        .append(tl)
        .append(tr)
        .append(bl);

      // adjust link strength and width based on threshold
      (function() {
        function linkStrength(link) {
          return (link.strength - dataProvider.threshold) / (1.0 - dataProvider.threshold);
        }
        graphView.getForceLayout().linkStrength(linkStrength);
        graphView.on("enter:link", function(enterSelection) {
          enterSelection.attr("stroke-width", function(link) { return 5 * linkStrength(link); });
        });
      })();

    },

  });

  return Celestrium;

});