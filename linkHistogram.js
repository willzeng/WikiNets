define(["backbone", "d3"], function(Backbone, d3) {

var margin = {top: 10, right: 30, bottom: 30, left: 30},
    width = 200 - margin.left - margin.right,
    height = 200 - margin.top - margin.bottom;

  var LinkHistogramView = Backbone.View.extend({

    initialize: function() {
      this.model.on("change:links", this.update, this);
    },

    render: function() {
      this.update();
      return this;
    },

    update: function() {

      console.log("updating");

      this.$el.empty();
      this.$el.append($("<div class='histogram-header'>Link Strength</div>"));
      var svg = d3.select(this.el).append("svg")
          .classed("histogram", true)
          .attr("width", width + margin.left + margin.right)
          .attr("height", height + margin.top + margin.bottom)
        .append("g")
          .classed("workspace", true)
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
     
      var values = _.pluck(this.model.getLinks(), "strength");

      // A formatter for counts.
      var formatCount = d3.format(",.0f");

      var min = d3.min(values) || 0;
      var max = d3.max(values) || 1;

      if (min === max) {
        max += .001;
      }

      var x = d3.scale.linear()
          .domain([min, max])
          .range([0, width]);

      var numBins = 5;
      var ticks = [];
      for (var i = 0; i < numBins + 1; ++i) {
        ticks.push(min + (max - min) * i / (numBins));
      }
      var data = d3.layout.histogram()
          .bins(ticks)
          (values);

      console.log(min, max, ticks, data);

      var y = d3.scale.linear()
          .domain([0, d3.max(data, function(d) { return d.y; })])
          .range([height, 0]);

      var xAxis = d3.svg.axis()
          .scale(x)
          .orient("bottom");

      var bar = svg.selectAll(".bar")
          .data(data)
        .enter().append("g")
          .attr("class", "bar")
          .attr("transform", function(d) { return "translate(" + x(d.x) + "," + y(d.y) + ")"; });

      bar.append("rect")
          .attr("x", 1)
          .attr("width", function(d) {return x(d.x + d.dx) - x(d.x) - 1;})//x(data[0].dx) - 1)
          .attr("height", function(d) { return height - y(d.y); });

      bar.append("text")
          .attr("dy", ".75em")
          .attr("y", 6)
          .attr("x", function(d) {return (x(d.x + d.dx) - x(d.x) - 1)/2;})
          .attr("text-anchor", "middle")
          .text(function(d) { return formatCount(d.y); });

      svg.append("g")
          .attr("class", "x axis")
          .attr("transform", "translate(0," + height + ")")
          .call(xAxis);

      },

  });

  return LinkHistogramView;

});