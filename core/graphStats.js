define(['jquery', 'backbone'], function($, Backbone) {

  var GraphStatsView = Backbone.View.extend({

    initialize: function() {
      this.model.on("change", this.update.bind(this));
    },

    render: function() {

      var container = $("<div />").addClass("graph-stats-container").appendTo(this.$el);
      var table = $('<table border="0"/>').appendTo(container);
      $('<tr><td class="graph-stat-label">Nodes: </td><td id="graph-stat-num-nodes" class="graph-stat">0</td></tr>').appendTo(table);
      $('<tr><td class="graph-stat-label">Links: </td><td id="graph-stat-num-links" class="graph-stat">0</td></tr>').appendTo(table);

      return this;

    },

    update: function() {
      this.$("#graph-stat-num-nodes").text(this.model.getNodes().length);
      this.$("#graph-stat-num-links").text(this.model.getLinks().length);
    },

  });

  return GraphStatsView;

});