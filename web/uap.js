var width = 960,
    height = 640;

/* render the data using force layout */
function render(svg, nodes, links) {

  $("#workspace").empty();

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
    .attr("class", "node")
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
  var svg = d3.select('#workspace')
    .attr("height", height)
    .attr("width", width)
  $("#input-search").keypress(function(e) {
    var val = $("#input-search").val();
    if (e.which === 13 && val.length > 0) {
      $.ajax({
        url: "/get_data",
        type: "GET",
        data: {text: val},
        success: function(response) {
          render(svg, response.nodes, response.links);
        },
      });
    }
  });
});