define(['jquery', 'backbone', 'd3'], function($, Backbone, d3) {

  function Selection(graphModel, graphView) {

    // handle selecting and deselecting nodes
    (function(selection) {
      var clickSemaphore = 0;
      graphView.on("enter:node", function(nodeEnterSelection) {
        nodeEnterSelection.on('click', function(datum, index) {
          if (d3.event.defaultPrevented) return; // ignore drag
          datum.fixed = true;
          clickSemaphore += 1;
          var savedClickSemaphore = clickSemaphore;
          setTimeout(function() {
            if (clickSemaphore === savedClickSemaphore) {
              selection.toggleSelection(datum);
              datum.fixed = false;
            } else {
              // increment so second click isn't registered as a click
              clickSemaphore += 1;
              datum.fixed = false;
            }
          }, 250);
        }).on('dblclick', function(datum, index) {
          selection.selectConnectedComponent(datum);
        });
      });
    })(this);

    this.renderSelection = function() {
      var nodeSelection = graphView.getNodeSelection();
      if (nodeSelection) {
        nodeSelection.call(function(selection) {
          selection.classed('selected', function(d) {
            return d.selected; 
          });
        });
      }
    };

    this.filterSelection = function(filter) {
      _.each(graphModel.getNodes(), function(node) {
        node.selected = filter(node);
      });
      this.renderSelection();
    };

    this.selectAll = function() {
      this.filterSelection(function(n) {
        return true;
      });
    };

    this.deselectAll = function() {
      this.filterSelection(function(n) {
        return false;
      });
    };
    
    this.toggleSelection = function(node) {
      node.selected = !node.selected;
      this.renderSelection();
    }

    this.removeSelection = function() {
      graphModel.filterNodes(function(node) {
        return !node.selected;
      });
    };

    this.removeSelectionCompliment = function() {
      graphModel.filterNodes(function(node) {
        return node.selected;
      });
    };

    this.getSelectedNodes = function() {
      return _.filter(graphModel.getNodes(), function(node) {
        return node.selected;
      });
    };

    // select all nodes which have a path to node
    // using links meeting current Connectivity criteria
    this.selectConnectedComponent = function(node) {

      // create adjacency list version of graph
      var graph = {};
      var lookup = {};
      _.each(graphModel.getNodes(), function(node) {
        graph[node.text] = {};
        lookup[node.text] = node;
      });
      _.each(graphModel.getLinks(), function(link) {
        graph[link.source.text][link.target.text] = 1;
        graph[link.target.text][link.source.text] = 1;
      });

      // perform DFS to compile connected component
      var seen = {};
      function visit(text) {
        if (!_.has(seen, text)) {
          seen[text] = 1;
          _.each(graph[text], function(ignore, neighborText) {
            visit(neighborText);
          }); 
        }
      }
      visit(node.text);

      // toggle selection appropriately
      // selection before ==> selection after
      //             none ==> all
      //             some ==> all
      //             all  ==> none
      var allTrue = true;
      _.each(seen, function(ignore, text) {
        allTrue = allTrue && lookup[text].selected;
      });
      var newSelected = !allTrue;
      _.each(seen, function(ignore, text) {
        lookup[text].selected = newSelected;
      });

      // update UI
      this.renderSelection();
    }

  };

  return Selection;
});