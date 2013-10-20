define(["jquery", "underscore", "backbone"], function($, _, Backbone) {

  return Backbone.View.extend({

    initialize: function(options) {
      this.selection = options.selection;
      this.selection.on("change", this.update.bind(this));
    },

    render: function() {
      return this;
    },

    update: function() {

      this.$el.empty();
      var selectedNodes = this.selection.getSelectedNodes();
      var $container = $('<div class="node-profile-helper"/>').appendTo(this.$el);
      var blacklist = ['index','x','y','px','py','fixed','selected','weight'];
      _.each(selectedNodes, function(node) {
        var $nodeDiv = $('<div class="node-profile"/>').appendTo($container);
        $('<div class="node-profile-title">' + node['text'] + '</div>').appendTo($nodeDiv);
        _.each(node, function(value, property) {
          if (blacklist.indexOf(property) < 0) {
            $('<div class="node-profile-property">' + property + ':  ' + value + '</div>').appendTo($nodeDiv);
          }
        });
      });
    },

    toggle: function() {
        this.$el.toggle();
    },

  });
});