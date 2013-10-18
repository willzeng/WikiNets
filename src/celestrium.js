/* main javascript for page */
define(["jquery", "src/graphModel", "src/graphView", "src/nodeSearch", "src/selection", "src/graphStats", "src/forceSliders", "src/linkChecker", "src/keyListener", "src/linkHistogram", "src/nodeProfile"], 
function($, GraphModel, GraphView, NodeSearch, Selection, GraphStatsView, ForceSlidersView, LinkChecker, KeyListener, LinkHistogramView, NodeProfile) {

  var Celestrium = Backbone.View.extend({

    initialize: function(options) {

      var nodePrefetch = this.nodePrefetch = options.nodePrefetch;
      var dataProvider = this.dataProvider = options.dataProvider;

      var graphModel = this.graphModel = new GraphModel({
        nodeHash: function(node) {
          return node.text;
        },
        linkHash: function(link) {
          return link.source.text + link.target.text;
        },
      });

      new LinkChecker(graphModel, dataProvider);

      var graphView = this.graphView = new GraphView({
        model: graphModel,
      }).render();


      new LinkChecker(graphModel, dataProvider);

      this.sel = new Selection(graphModel, graphView);

      // adjust link strength and width based on threshold
      (function() {
        function linkStrength(link) {
          return (link.strength - dataProvider.minThreshold) / (1.0 - options.dataProvider.minThreshold);
        }
        graphView.getForceLayout().linkStrength(linkStrength);
        graphView.on("enter:link", function(enterSelection) {
          enterSelection.attr("stroke-width", function(link) { return 5 * linkStrength(link); });
        });
      })();

    },


    render: function() {


      

      var keyListener = new KeyListener(document.querySelector("body"));

      var sel = this.sel;

      var nodeProfile = new NodeProfile({
        selection: sel
      }).render();

      // CTRL + A
      keyListener.on("down:17:65", sel.selectAll, sel);
      // ESC
      keyListener.on("down:27", sel.deselectAll, sel);

      // p
      keyListener.on("down:80", nodeProfile.toggle, nodeProfile);

      // DEL
      keyListener.on("down:46", sel.removeSelection, sel);
      // ENTER
      keyListener.on("down:13", sel.removeSelectionCompliment, sel);

      // PLUS
      (function() {
        var graphModel = this.graphModel;
        var dataProvider = this.dataProvider;
        keyListener.on("down:16:187", function() {
          dataProvider.getLinkedNodes(sel.getSelectedNodes(), function(nodes) {
            _.each(nodes, function(node) {
              graphModel.putNode(node);
            });
          });
        });
      }.bind(this))();

      // FORWARD_SLASH
      keyListener.on("down:191", function(e) {
        $(".node-search-input").focus();
        e.preventDefault();
      });

      this.$el.append(this.graphView.el);

      var graphStatsView = new GraphStatsView({
        model: this.graphModel,
      }).render();

      var forceSlidersView = new ForceSlidersView({
        graphView: this.graphView,
      }).render();

      var linkHistogramView = new LinkHistogramView({
        model: this.graphModel,
      }).render();

      var tl = $('<div id="top-left-container" class="container"/>');
      tl.append(forceSlidersView.el);
      tl.append(linkHistogramView.el);

      var bl = $('<div id="bottom-left-container" class="container"/>');
      bl.append(graphStatsView.el);

      var br = $('<div id="bottom-right-container" class="container"/>');
      br.append(nodeProfile.el);

      this.$el
        .append(tl)
        .append(bl)
        .append(br);

      if (this.nodePrefetch) {
        var nodeSearch = new NodeSearch({
          graphModel: this.graphModel,
          prefetch: this.nodePrefetch,
        }).render();
        var tr = $('<div id="top-right-container" class="container"/>');
        tr.append(nodeSearch.el);
        this.$el.append(tr);
      }

    },

  });

  return Celestrium;

});