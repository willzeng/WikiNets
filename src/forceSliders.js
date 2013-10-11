define(["jquery", "underscore", "backbone"], function($, _, Backbone) {

  return Backbone.View.extend({

    initialize: function(options) {

      var force = options.graphView.getForceLayout();
      
      var $container = $('<div class="force-sliders-container" />').appendTo(this.$el);
      var $table = $('<table border="0" />').appendTo($container);
      $('<tr><td class="slider-label">Charge: </td><td><input id="input-charge" type="range" min="0" max="100"></td></tr>').appendTo($table);
      $('<tr><td class="slider-label">Gravity: </td><td><input id="input-gravity" type="range" min="0" max="100"></td></tr>').appendTo($table);

      // define mappings between values in code and values in UI
      var mappings = [
        {
          f: force.charge,
          selector: "#input-charge",
          scale: d3.scale.linear()
            .domain([-20, -2000])
            .range([0, 100]),
        },

        {
          f: force.gravity,
          selector: "#input-gravity",
          scale: d3.scale.linear()
            .domain([0.01, 0.5])
            .range([0, 100]),
        },
      ]

      // hook mappings up to respond to user input
      _.each(mappings, function(mapping) {
        this.$(mapping.selector)
          .val(mapping.scale(mapping.f()))
          .change(function() {
            mapping.f(mapping.scale.invert($(this).val()));
            force.start(); // TODO: too much rep-exposure?
        });
      }.bind(this));

      return this;

    },

  });
});