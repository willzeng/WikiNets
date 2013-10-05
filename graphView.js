define(['jquery', 'underscore', 'backbone', 'd3'], function($, _, Backbone, d3) {

  var GraphView = Backbone.View.extend({

    initialize: function() {
      this.model.on("change", this.update.bind(this));
      _.extend(this, Backbone.Events);
    },

    render: function() {

      var initialWindowWidth = $(window).width();
      var initialWindowHeight = $(window).height();

      this.force = d3.layout.force().size([initialWindowWidth, initialWindowHeight]);

      var svg = d3.select(this.el)
        .append("svg:svg")
          .attr("pointer-events", "all");

      var zoom = d3.behavior.zoom();

      // outermost wrapper - this is used to capture all zoom events
      var zoomCapture = svg.append('g');

      // this is in the background to capture events not on any node  
      // should be added first so appended nodes appear above this
      zoomCapture.append('svg:rect')
        .attr("width", "100%")
        .attr("height", "100%")
        .style("fill-opacity", "0%");

      // lock infrastracture to ignore zoom changes that would
      // typically occur when dragging a node
      var translateLock = false;
      var currentZoom;
      this.force.drag()
        .on('dragstart', function() {
          translateLock = true;
          currentZoom = zoom.translate();
        })
        .on('dragend', function() {
          zoom.translate(currentZoom);
          translateLock = false;
        });

      // add event listener to actually affect UI
      zoomCapture.call(zoom.on("zoom", function() {

        // ignore zoom event if it's due to a node being dragged
        if (translateLock) return;

        // otherwise, translate and scale according to zoom
        workspace.attr("transform",
            "translate(" + d3.event.translate + ")" + 
            " scale(" + d3.event.scale + ")");
      }))
      .on("dblclick.zoom", null); // ignore double click to zoom

      // inner workspace which nodes and links go on
      // scaling and transforming are abstracted away from this
      var workspace = zoomCapture.append('svg:g');

      // containers to house nodes and links
      // so that nodes always appear above links
      var linkContainer = workspace.append('svg:g').classed("linkContainer", true);
      var nodeContainer = workspace.append('svg:g').classed("nodeContainer", true);

      return this;

    },

    update: function() {

      var nodes = this.model.get("nodes");
      var links = this.model.get("links");

      this.force.nodes(nodes)
                .links(links)
                .start();

      this.force.linkStrength(function(link) { return (link.strength - 0.95) / (1.0 - 0.95); });

      var link = d3.select(".linkContainer").selectAll(".link")
          .data(links, this.model.get("linkHash"));
      link.enter().append("line").attr("class", "link").attr("stroke-width", function(link) { return 5 * (link.strength - 0.95) / (1.0 - 0.95); });
      link.exit().remove();

      var node = this.nodeSelection = d3.select(".nodeContainer").selectAll(".node")
        .data(nodes, this.model.get("nodeHash"));

      var nodeEnter = node.enter().append("g")
        .attr("class", "node")
        .call(this.force.drag);

      nodeEnter.append("text")
        .attr("dx", 12)
        .attr("dy", ".35em")
        .text(function(d) { return d.text; });
      nodeEnter.append("circle")
        .attr("r", 5)
        .attr("cx", 0)
        .attr("cy", 0);

      this.trigger("enter:node", nodeEnter);

      node.exit().remove();

      this.force.on("tick", function() {

        link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });

        node.attr("transform", function(d) { 
          return "translate(" + d.x + "," + d.y + ")"; 
        });
      });
    },

    getNodeSelection: function() {
      return this.nodeSelection;
    },

    getForceLayout: function() {
      return this.force;
    },

  });

  return GraphView;

});