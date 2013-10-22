/* the size of the graph and subgraph; also used as scaling factors */
var width = 960,
    height = 500;

/* This variable holds the graph data: an array of links and an array of nodes
   as provided by the server upon an AJAX call to "/json" -- see below */
var graph;

/* Make AJAX query to get JSON data for visualization */
$.getJSON('/json', function(data){
  graph = data;
  console.log("make call for json");
  // for debugging:
  //console.log(graph);

  /* This variable contains a dictionary of all node types, where the value
     associated with each type is a list of all nodes of that type -- see
     function right below */
  var obj = {};
  /* Figuring out what node groups there are in the graph - this should
     eventually be changed to use node types instead */
  graph.nodes.forEach( function(d) { 
    if(! (d.group in obj) ){
      obj[d.group] = [];
    }
    obj[d.group].push(d);
  });
  // for debugging:
  //console.log(obj);

  /* Tests whether a and b are adjacent (ignoring edge direction) */
  function neighboring(a, b) {
    var links=graph.links;
    return links.some(function(d) {
      return (d.source === a && d.target === b)
        || (d.source === b && d.target === a);
    });
  }

  /* Displays node information in InfoBox and (if open) EditNode menu */
  function node_info(d, i, th) { 
    // Use data from existing JSON to put into InfoBar div
    // Should replace this with something more versatile
    var theinfo = "This node is called: "+ d.name + "\<br\> Info: " + d.Info;
    $('#infobox').html(theinfo);
    // if "Edit Node" menu is visible, fill in data for selected node
    if ($("#en_1").css("display") == "block") {
      selected_node = d._id;
      $("#SelectNodeID").val(selected_node);
      select_node(selected_node);
    };
    // update subgraph to centre on newly-selected node
    setup_subgraph(d, i, th);
  };


  /* Sets up the small circular graph at the bottom. Don't understand details
     yet */
  function setup_subgraph(d, i, th){
    svg.selectAll(".node").attr("r", function(d_1) {
      if(d_1 === d){
        return 20;
      }
      return 10;
    }).style("stroke", function(d_1) { 
      if(d_1 === d){
        return "red";
      }
      return "none";
    }).style("fill", function(d_1) { 
      if(d_1 === d){
        return "lightcoral";
      }
      return color(d_1.group);
    });

    d3.select(th).attr('r', 25)
      .style("fill","lightcoral")
      .style("stroke","red");

    d3.select("#subNet svg").remove();

    var central_width=40;
    var frame = d3.select("#subNet").append("svg:svg").attr("width", width)
                  .attr("height", height);
    var nodelist=graph.nodes
    var neighbors = nodelist.filter(function(d_2){
          return neighboring(d_2, d);
        });
               
    frame.selectAll("line").data(neighbors).enter().append("line")
         .attr("x1", width/2+central_width/2)
         .attr("y1", height/2+central_width/2)
         .attr("x2", function(d_2, i_2){
           return 150*Math.cos(2*i_2*Math.PI/neighbors.length)+width/2+central_width/2;
         })
         .attr("y2", function(d_2, i_2){
           return 150*Math.sin(2*i_2*Math.PI/neighbors.length)+height/2+central_width/2;
         })
         .style("stroke", "lightgrey")
         .style("stroke-width", "2");

    frame.selectAll("rect").data([th]).enter().append("rect")
         .attr("x", width/2).attr("y", height/2).attr("width", central_width)
         .attr("height", central_width).attr("fill", "lightblue");
                
    frame.selectAll(".node").data(neighbors).enter().append("circle")
         .attr("class", "node")
         .attr("r", function(d_2, i_2){
           if(neighboring(d, d_2)) return 30;
           return 0;
         })
         .attr("fill", "pink")
         .attr("cx", function(d_2, i_2){
           return 150*Math.cos(2*i_2*Math.PI/neighbors.length)+width/2+central_width/2;
         })
         .attr("cy", function(d_2, i_2){
           return 150*Math.sin(2*i_2*Math.PI/neighbors.length)+height/2+central_width/2;
         })
         .on("click", function(d_2, i_2) {
           // update node info if node is clicked in subgraph
           node_info(d_2, i_2, this);
         });

                
    //window.alert(Math.random());
    //frame.selectAll("circle").data([this]).enter().append("circle").attr("class", "node").attr("cx", width/2).attr("cy", height/2).attr("fill", "lightblue").attr("r", 25);

    frame.selectAll("text").data(neighbors).enter().append("text")
         .attr("fill", "black")
         .attr("font-size", 18)
         .attr("x", function(d_2, i_2){
           return 150*Math.cos(2*i_2*Math.PI/neighbors.length)+width/2+5;
         })
         .attr("y", function(d_2, i_2){
           return 150*Math.sin(2*i_2*Math.PI/neighbors.length)+height/2+central_width/2+5;
         })
         .text(function(d_2){ return d_2.name; })
         .on("click", function(d_2, i_2) {
           // update node info if node label is clicked in subgraph
           node_info(d_2, i_2, this);
         });

    frame.selectAll("text.label").data([th]).enter().append("text")
         .attr("fill", "black")
         .attr("font-size", 18)
         .attr("x", function(d_2, i_2){
           return width/2+5;
         })
         .attr("y", function(d_2, i_2){
           return height/2-1+central_width/2;
         })
         .text(function(d_2){ return d.name; });
         //    .text(function(d){return d.name;});
  }
  // end of "setup_subgraph"


  //var button=d3.select("body").selectAll("button").data(obj).enter().append("button").attr("type", "button").text("button");

  var color = d3.scale.category20();

  var force = d3.layout.force()
                .charge(-360)
                .linkDistance(50)
                .size([width, height]);

  // creates a place for the grey-out buttons to go at bottom of body
  var div0 = d3.select("body").append("div")
               .attr("name", "options")
               .attr("id", "options");

  // creates place for the main graph
  var div1 = d3.select("body").append("div")
               .attr("name", "mainNet")
               .attr("id", "mainNet");

  // creates place for the subgraph
  var div2 = d3.select("body").append("div")
               .attr("name", "subNet")
               .attr("id", "subNet");

  // creates a vector graphics environment in the section for the main graph
  var svg = d3.select("#mainNet").append("svg")
              .attr("width", width)
              .attr("height", height);

  /* add data for markers -- might have to fiddle a bit if node sizes change 
     -- really this should all be relative to some global variables */
  d3.select("svg").append("defs").append("marker")
    .attr("id", "Triangle")
    .attr("viewBox", "0 0 10 10")
    .attr("refX", "25")
    .attr("refY", "5")
    .attr("markerUnits", "strokeWidth")
    .attr("markerWidth", "8")
    .attr("markerHeight", "6")
    .attr("orient", "auto");
  d3.select("marker").append("path")
    .attr("d", "M 0 0 L 10 5 L 0 10 z");


  force
      .nodes(graph.nodes)
      .links(graph.links)
      .start();

  var link = svg.selectAll(".link")
      .data(graph.links)
      .enter().append("line")
      .attr("class", "link")
      .attr("marker-end", "url(#Triangle)");
      // not sure what this is supposed to do?
      //.style("stroke-width", function(d) { return Math.sqrt(d.value); });
  
  var node = svg.selectAll(".node")
      .data(graph.nodes)
      .enter().append("circle")
      .attr("class", "node")
      .attr("r", 10)
      .on("click", function(d, i) {
        // update node info if node is clicked in main graph
        node_info(d, i, this);
      })
      .style("fill", function(d) { return color(d.group); })
      .call(force.drag);

  var texts = svg.selectAll("text.label")
                 .data(graph.nodes)
                 .enter().append("text")
                 .attr("class", "label")
                 .attr("fill", "black")
                 .attr("font-size", 18)
                 .text(function(d) {  return d.name;  });

  node.append("title")
      .text(function(d) { return d.name; });

  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node.attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; });
    
    texts.attr("transform", function(d) {
        return "translate(" + d.x + "," + d.y + ")";
    });
  });


  /* Generates buttons that grey out all nodes not belonging to the chosen
     group, putting them in the "options" container.
     The selectAll("div") is a bit of a hack; the function specifically expects
     the "options" container not to contain any "div"s. */
  var b=d3.select("#options").selectAll("div")
          .data(Object.keys(obj)).enter()
          .append("button")
          .attr("type", "button")
          .text(function(d){
            return "see "+d;
          })
          .on("click", function(d) { 
            svg.selectAll(".node").attr("r", function(d_1) {
              // set node radius
              if(d_1.group.toString() === d){
                return 10;
              }
              return 5;
            })
            .style("stroke", function(d_1) {
              if(d_1.group.toString() === d){
                return "none";
              } 
              return "none";
            })
            .style("fill", function(d_1) {
              // set node colour
              if(d_1.group.toString() === d){
                return color(d_1.group);
              }
              return "lightgrey";
            });
          });

  /*
  for(var d in obj){
    svg.selectAll(".node").attr("r", function(d_1) {
      if(d_1.group.toString() === button_map[this].toString()){
        return 10;
      }
      return 5;
    }).style("stroke", function(d_1) { 
      return "none";
    }).style("fill", function(d_1) { 
      if(d_1.group.toString() == button_map[this].toString()){
        return "red";
      }
      return "grey";
    });
  });
  button_map[b]=d;
}
*/

});

