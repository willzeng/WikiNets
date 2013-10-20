define(['jquery', 'jquery.typeahead', 'backbone'], function($, ignore, Backbone) {

  var NodeSearch = Backbone.View.extend({

    events: {
      'typeahead:selected input': "addNode",
    },

    initialize: function(options) {
      this.graphModel = options.graphModel;
      this.prefetch = options.prefetch;
    },

    render: function() {

      var $container = $("<div />").addClass("node-search-container");
      var $input = $('<input type="text" placeholder="Node Search...">').addClass("node-search-input");
      $container.append($input);
      this.$el.append($container);

      $input.typeahead({
        prefetch: this.prefetch,
        name: "nodes",
        limit: 100,
      });

      return this;

    },

    addNode: function(e, datum) {
      var graphModel = this.graphModel;
      var newNode = {text: datum.value};
      var h = graphModel.get("nodeHash");
      var newNodeHash = h(newNode);
      if (!_.some(graphModel.get("nodes"), function(node) {
        h(node) === newNodeHash;
      })) {
        graphModel.putNode(newNode);
      }
      $(e.target).blur();
    },

  });

  return NodeSearch;

});
