define(["jquery", "underscore", "backbone"], function($, _, Backbone) {

  return Backbone.View.extend({

    render: function() {
    
      
      var $container = $('<div class="force-sliders-container" />').appendTo(this.$el);
      var $table = $('<table border="0" />').appendTo($container);
      $('<tr><td class="slider-label">Node Profile </td><td><input id="input-charge" type="range" min="0" max="100"></td></tr>').appendTo($table);
      
      console.dir(this.options.selection);
      return this;

    },

    select: function() {
      console.log(this.selection);
    },

  });
});