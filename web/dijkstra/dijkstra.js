var width = 960,
    height = 600;

var dt = 1000;

// @src, @dest are strings of concepts
function initSearch(svg, src, dest) {

  var force = d3.layout.force()
    .charge(-400)
    .linkDistance(30)
    .linkStrength(function(d) {return d.strength; })
    .size([width, height]);

  var nodes = []
  var links = []

  function syncGraph() {

    var link = svg.selectAll(".link")
        .data(links, function(l) {return l.source.text + l.target.text; });

    link.enter().append("line")
        .attr("class", "link")
        .style("stroke-width", function(d) { return 2 * d.strength; })
        .style("opacity", function(d) {
          return (d.source.strength + d.target.strength) / 2;
        });

    link.exit().remove();

    var node = svg.selectAll(".node")
        .data(nodes, function(d) {return d.text; })

    var nodeEnter = node.enter().insert("g")
        .attr("class", "node")
        .call(force.drag);

    nodeEnter
      .attr("fill", "red")
      .transition()
      .duration(dt)
      .attr("fill", function(d) {
        if (d.text === src || d.text === dest) {
          return "lime";
        } else {
          return "black";
        }
      })
      .style("opacity", function(d) {return d.strength; });

    nodeEnter.append("text")
      .attr("dx", 12)
      .attr("dy", ".35em")
      .text(function(d) {return d.text;});

    nodeEnter.append("circle")
      .attr("r", 5)
      .attr("cx", 0)
      .attr("cy", 0);

    nodeEnter.append('title')
      .text(function(d) {return d.text; });

    node.exit().remove();

    force.on("tick", function() {
      link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

      node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

    });

    force
      .nodes(nodes)
      .links(links)
      .start();

  }

  var queue = [{text: src, strength: 1, parent: null}]
  var seen = {};
  
  // helpful abstraction of when to know to stop
  function isTerminal(node) {
    return node.text === dest;
  }

  // thunk to do the next node
  function doNext() {
    
    // retreive datum with highest cumulative confidence
    var next = queue.pop();
    seen[next.text] = 1;
    
    // add to graph
    var currentNodeNames = _.pluck(nodes, "text");
    $.ajax({
      url: "/get_link_strengths",
      data: {nextNode: next.text, currentNodes: JSON.stringify(currentNodeNames)},
      type: "POST",
      success: function(response) {
        
        // response.links is an array of {strength: ___}
        //                               ^ relatedness of node at nodes[i] and next


        // add node to force layout
        nodes.push(next)
        
        // add links to already present nodes to force layout
        _.each(response.links, function(link, i) {
          if (link.strength > 0.75) {
            links.push({source: nodes[i], target: next, strength: link.strength});
          }
        });

        syncGraph();

        if (isTerminal(next)) {
          return;
        }
        
        // progress dijkstra
        $.ajax({
          url: "/get_top_items",
          data: {text: next.text, limit: 10},
          type: "GET",
          success: function(response) {
            // response.related is an array of {text: ___, strength: ___}
            //                                             ^ = relatedness to next
            _.each(response.related, function(related) {
              var cumulativeStrength = next.strength * related.strength;
              var obj = {text: related.text, strength: cumulativeStrength, parent: next}
              if (!_.has(seen, obj.text)) {
                queue.push(obj);
                seen[obj.text] = 1;
              } else {
                var inQueue = _.find(queue, function(x) { return x.text === obj.text; });
                if (inQueue) {
                  inQueue.cumulativeStrength = Math.max(inQueue.cumulativeStrength, obj.cumulativeStrength);
                }
              }
            });
            queue = _.sortBy(queue, function(obj) {return obj.strength; });
            setTimeout(doNext, dt);
          },
        })
      },
    });
  }
  // initiate sequence of callbacks
  doNext();
}

$(function() {
  var svg = d3.select("#workspace")
    .attr("width", width)
    .attr("height", height);

  $("#btn-go").click(function() {
    var src = $("#input-src").val();
    var dest = $("#input-dest").val();
    initSearch(svg, src, dest);
  })

});