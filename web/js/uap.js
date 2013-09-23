var width = 960,
    height = 600;

/* render the data using force layout */
function render(svg, nodes, links) {

  $(".node, .link").remove();

  var force = d3.layout.force()
    .charge(-400)
    .linkDistance(30)
    .linkStrength(function(d) { return d.strength; })
    .size([width, height])

  force
    .nodes(nodes)
    .links(links)
    .start()

   var link = svg.selectAll(".link")
      .data(links)
    .enter().append("line")
      .attr("class", "link")
      .style("stroke-width", 1);  

  var node = svg.selectAll(".node")
      .data(nodes)
    .enter().append("g")
      .attr("class", "node")
      .call(force.drag);
    
  node.append("text")
    .attr("dx", 12)
    .attr("dy", ".35em")
    .text(function(d) {return d.text;});

  node.append("circle")
    .attr("r", 5)
    .attr("cx", 0)
    .attr("cy", 0);

  node.append('title')
    .text(function(d) {return d.text; });

  force.on("tick", function() {
    link
      .attr("x1", function(d) { return d.source.x; })
      .attr("y1", function(d) { return d.source.y; })
      .attr("x2", function(d) { return d.target.x; })
      .attr("y2", function(d) { return d.target.y; });

    node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

  });
}

$(function() {
  var svg = d3.select("#workspace")
    .append("svg:svg")
      .attr("width", width)
      .attr("height", height)
      .attr("pointer-events", "all")

  var zoom = d3.behavior.zoom();
  var zoomCapture = svg.append('g')
      .classed('zoom-capture', true)
      .append('svg:rect')
        .attr('width', width)
        .attr('height', height)
        .attr('fill', 'white')
        .style('stroke', 'black');
  
  var vis = svg.append('svg:g');

  zoomCapture.call(zoom.on("zoom", redraw))

  function redraw() {
    vis.attr("transform",
        "translate(" + d3.event.translate + ")" + 
        " scale(" + d3.event.scale + ")");
  }

  $("#input-search").keypress(function(e) {
    var val = $("#input-search").val();
    if (e.which === 13 && val.length > 0) {
      $.ajax({
        url: "/get_data",
        type: "GET",
        data: {text: val},
        success: function(response) {
          render(vis, response.nodes, response.links);
        },
        error: function(response) {
          alert(val + " was not found as a concept. Please try something else.");
        }
      });
    }
  });

});