//var width = 960,
//    height = 500;

var pan = [0, 0]; // pan to a node
var trans = [0, 0]; // translation from zooming
var scale = 1;


var fisheye = d3.fisheye()
    .radius(50)
    .power(2);

//var color = d3.scale.category20();
/*
var force = d3.layout.force()
    .charge(-120)
    .linkDistance(50)
    .size([width, height]);*/



// get size of viewport on load
// might want to make this dynamic at some point?
var viewportwidth;
var viewportheight;
if (typeof window.innerWidth != 'undefined') {
  // Standards compliant browsers (mozilla/netscape/opera/IE7)
  viewportwidth = window.innerWidth,
  viewportheight = window.innerHeight
} else if (typeof document.documentElement != 'undefined'
 && typeof document.documentElement.clientWidth !=
 'undefined' && document.documentElement.clientWidth != 0) {
  // IE6
  viewportwidth = document.documentElement.clientWidth,
  viewportheight = document.documentElement.clientHeight
} else {
  // Older IE
  viewportwidth = document.getElementsByTagName('body')[0].clientWidth,
  viewportheight = document.getElementsByTagName('body')[0].clientHeight
}

/* the size of the graph and subgraph; also used as scaling factors */
var width = viewportwidth-480,
height = viewportheight-160;
subwidth=300;
subheight=300;

/* This variable holds the graph data: an array of links and an array of nodes
as provided by the server upon an AJAX call to "/json" -- see below */

var graph;

function updategraph()
{
  console.log(graph);
  /* Make AJAX query to get JSON data for visualization */
  $.getJSON('/json', function(data){
    graph = data;
    console.log("update viz called");
    console.log(graph);
  });
}

/* Make AJAX query to get JSON data for visualization */
//function loadviz()
//{
//$.getJSON('/json', function(data){
//  graph = data;
//  console.log("make call for json");
//  console.log(graph);
//});
//}


/* Make AJAX query to get JSON data for visualization */
$.getJSON('/json', function(data){
  graph = data;
  console.log("make call for json");
  console.log(graph);

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

    //changes the selected name at the top of the sidebar
    $('#selectednamebox').html(d.name);

    // if "Edit Node" menu is visible, fill in data for selected node
    //if ($("#en_1").css("display") == "block") {
      window.selected_node = d._id;
      $("#SelectNodeID").val(window.selected_node);
      select_node(window.selected_node);
    //};
    // update subgraph to centre on newly-selected node
    setup_subgraph(d, i, th);
  };


  /* add data for markers -- might have to fiddle a bit if node sizes change 
  -- really this should all be relative to some global variables */
  function set_marker_data(section, scale) {
    d3.select("#" + section + " svg").append("defs").append("marker")
    .attr("id", section+"Triangle")
    .attr("viewBox", "0 0 10 10")
    .attr("refX", 30*scale)
    .attr("refY", 5)
    .attr("markerUnits", "strokeWidth")
    .attr("markerWidth", 8*scale)
    .attr("markerHeight", 6*scale)
    .attr("orient", "auto");
    d3.select("#" + section + " marker").append("path")
    .attr("d", "M 0 0 L 10 5 L 0 10 z");
  };


  /* Sets up the small circular graph at the bottom. Don't understand details
  yet */
  function setup_subgraph(d, i, th){

    /* This bit of code turns the selected node in the main graph into a
       large pink circle with red edge and returns any other node to its
       default radius and colour */
       svgG.selectAll(".node").attr("r", function(d_1) {
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

      /* remove previous subgraph and prepare a new one */
      d3.select("#subNet svg").remove();
      var frame = d3.select("#subNet").append("svg:svg").attr("width", subwidth)
      .attr("height", subheight);

    // this bit doesn't help very much at the moment as we aren't using
    // arrowheads in the subgraph
    set_marker_data("subNet", 1.5);

    // make a list of the neighbours of the selected node
    var nodelist=graph.nodes
    var neighbors = nodelist.filter(function(d_2){
      return neighboring(d_2, d);
    });

    // This is the width of the center node of the subgraph
    var central_width=20;
    // The radius of the circle for each neighbor
    var circle_sizer=20;
    // padding around the drawn subgraph
    var subgraph_padding = 30;
    // scales the size of the subgraph to match the framesize
    var subgraph_scalar = subwidth/2-central_width/2-circle_sizer-subgraph_padding;

    //This code draws the spokes out from the central node in the subgraph  
    frame.selectAll("line").data(neighbors).enter().append("line")
    .attr("x1", subwidth/2+central_width/2)
    .attr("y1", subheight/2+central_width/2)
    .attr("x2", function(d_2, i_2){
     return subgraph_scalar*Math.cos(2*i_2*Math.PI/neighbors.length)+subwidth/2+central_width/2;
   })
    .attr("y2", function(d_2, i_2){
     return subgraph_scalar*Math.sin(2*i_2*Math.PI/neighbors.length)+subheight/2+central_width/2;
   })
         /* all lines in subgraph currently go from centre to neighbours
            so arrow directions are meaningless -- will have to change this
            before implementing arrowheads in subgraph */
         //.attr("marker-end", "url(#subNetTriangle)")
         .style("stroke", "lightgrey")
         .style("stroke-width", "2")
         .on("click", function(d_2, i_2) {
           // will need to add actual functionality here once it's available
           alert("You clicked a link!");
           console.log(d_2);
           console.log(i_2);
         });

    //Draws the central node in the subgraph as a light blue square
    frame.selectAll("rect").data([th]).enter().append("rect")
    .attr("x", subwidth/2).attr("y", subheight/2).attr("width", central_width)
    .attr("height", central_width).attr("fill", "lightblue");

    //Draws the neighbors in the subgraph as red circles
    frame.selectAll(".node").data(neighbors).enter().append("circle")
    .attr("class", "node")
    .attr("r", function(d_2, i_2){
     if(neighboring(d, d_2)) return circle_sizer;

     return 0;
   })
    .attr("fill", "pink")
    .attr("cx", function(d_2, i_2){
     return subgraph_scalar*Math.cos(2*i_2*Math.PI/neighbors.length)+subwidth/2+central_width/2;
   })
    .attr("cy", function(d_2, i_2){
     return subgraph_scalar*Math.sin(2*i_2*Math.PI/neighbors.length)+subheight/2+central_width/2;
   })
    .on("click", function(d_2, i_2) {
           // update node info if node is clicked in subgraph
           node_info(d_2, i_2, this);
         });

    var subgraph_text_size=16;//font size of the subgraph text labels

    //Draws the text lables on the neighors in the subgraph
    frame.selectAll("text").data(neighbors).enter().append("text")
    .attr("fill", "black")
    .attr("font-size", subgraph_text_size)
    .attr("x", function(d_2, i_2){
     return subgraph_scalar*Math.cos(2*i_2*Math.PI/neighbors.length)+subwidth/2+5;
   })
    .attr("y", function(d_2, i_2){
     return subgraph_scalar*Math.sin(2*i_2*Math.PI/neighbors.length)+subheight/2+central_width/2+5;
   })
    .text(function(d_2){ return d_2.name; })
    .on("click", function(d_2, i_2) {
           // update node info if node label is clicked in subgraph
           node_info(d_2, i_2, this);
         });

    //Draws the text label on the central node in the subgraph
    frame.selectAll("text.label").data([th]).enter().append("text")
    .attr("fill", "black")
    .attr("font-size", subgraph_text_size)
    .attr("x", function(d_2, i_2){
     return subwidth/2+5;
   })
    .attr("y", function(d_2, i_2){
     return subheight/2-1+central_width/2;
   })
    .text(function(d_2){ return d.name; });
  };
  // end of "setup_subgraph"


  var color = d3.scale.category20();

  var force = d3.layout.force()
  .charge(-360)
  .linkDistance(50)
  .size([width, height]);

  // creates a place for the grey-out buttons to go at bottom of body
  var div0 = d3.select("#togglebox").append("div")
  .attr("name", "options")
  .attr("id", "options");

  // creates place for the main graph
  var div1 = d3.select("#maingraph").append("div")
  .attr("name", "mainNet")
  .attr("id", "mainNet")

  // creates place for the subgraph
  var div2 = d3.select("#subgraphcontainer").append("div")
  .attr("name", "subNet")
  .attr("id", "subNet");


  // creates a vector graphics environment in the section for the main graph
  /*var svgContainer = d3.select("#mainNet").append("svg")
              .attr("width", width)
              .attr("height", height);*/

    var svgContainer = d3.select("#mainNet").append("svg:svg")
      .attr("width", width)
      .attr("height", height)
    .attr("pointer-events", "all")
  .append('svg:g')
    .call(d3.behavior.zoom().on("zoom", redraw))


  set_marker_data("mainNet", 0.75);

  var svgG=svgContainer.append("svg:g");
  svgG.append('svg:rect')
    .attr('width', width)
    .attr('height', height)
    .attr('fill', 'black');

drawXHairs(width/2,height/2);
  svgContainer.on("mousemove", function() {

      fisheye.center(d3.mouse(this));


    var d=this;

    svgContainer.selectAll('.node')
    .each(function(d) { 
        d.display = fisheye(d); 
    })
    .attr("r", function(d) { return d.display.z * 4.5; });

  //console.log(d)
  return;
  /*var x_center = width / 2;
  var y_center = height / 2;

  var dx = d.x - x_center;
  var dy = d.y - y_center;

  svgG.selectAll('.node')
  .update()
  .each(function(d) { 
      //d.display = fisheye(d); 
    })  
      .attr('cx', function(curr) { return curr.x - dx }) // x attribute
      .attr('cy', function(curr) { return curr.y - dy })
      .attr("r", function(d) { return d.display.z * 4.5; });*/

    });



  force
  .nodes(graph.nodes)
  .links(graph.links)
  .start();

  var link = svgG.selectAll(".link")
  .data(graph.links)
  .enter().append("line")
  .attr("class", "link")
  .style("stroke-width", function(d) { return Math.sqrt(d.value); });

  var node = svgG.selectAll(".node")
  .data(graph.nodes)
  .enter().append("circle")
  .on("mouseover", translate)
  .attr("class", "node")
  .attr("r", 5)
  .style("fill", function(d) { return color(d.group); })
  .call(force.drag);

  node.append("title")
  .text(function(d) { return d.name; });

  force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x; })
    .attr("y1", function(d) { return d.source.y; })
    .attr("x2", function(d) { return d.target.x; })
    .attr("y2", function(d) { return d.target.y; });

    node.attr("cx", function(d) { return d.x; })
    .attr("cy", function(d) { return d.y; });
  });

  /*var link = svgG.selectAll(".link")
      .data(graph.links)
      .enter().append("line")
      .attr("class", "link")
      .attr("marker-end", "url(#mainNetTriangle)")
      .style("stroke-width", 2)
      .on("click", function(d, i) {
        // will need to add actual functionality here once it's available
        alert("You clicked a link!");
        console.log(d);
        console.log(i);
      });
  
  var node = svgG.selectAll(".node")
      .data(graph.nodes)
      .enter().append("circle")
      .attr("class", "node")
      .attr("r", 10)
      .on("click", function(d, i) {
        // update node info if node is clicked in main graph
        node_info(d, i, this);
      })
      .style("fill", function(d) { return color(d.group); })
      .call(force.drag);*/

      var texts = svgG.selectAll("text.label")
      .data(graph.nodes)
      .enter().append("text")
      .attr("class", "label")
      .attr("fill", "black")
      .attr("font-size", 18)
      .text(function(d) {  return d.name;  })
      .on("click", function(d, i) {
                   // update node info if text is clicked in main graph
                   node_info(d, i, this.parent);
                 });

      node.append("title")
      .text(function(d) { return d.name; });

  /*force.on("tick", function() {
    link.attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

    node.attr("cx", function(d) { return d.x; })
        .attr("cy", function(d) { return d.y; });
    
    texts.attr("transform", function(d) {
        return "translate(" + d.x + "," + d.y + ")";
    });
});*/


function drawXHairs(x,y) {

  svgG.append("line")
  .attr("x1", x)
  .attr("x2", x)
  .attr("y1", y-10)
  .attr("y2", y+10)
  .attr("stroke-width", 2)
  .attr("stroke", "red");
  svgG.append("line")
  .attr("x1", x+10)
  .attr("x2", x-10)
  .attr("y1", y)
  .attr("y2", y)
  .attr("stroke-width", 2)
  .attr("stroke", "red");
}


function translate() {
  // pan that node to the center
  var x = this.cx.animVal.value, y = this.cy.animVal.value;
 // d3.select(this).transition().attr("r",7)
 pan[0] = -x;
 pan[1] = -y;
 console.log("translate",width/2,height/2)
 console.log(x,y)
 // drawXHairs(x,y)
 redraw();
}

function redraw() {
  if(d3.event.translate){
    // zoom
    trans = d3.event.translate;
    scale = d3.event.scale;
  }
  console.log("redraw",trans,scale);
  var translate = [
  pan[0] + width/scale/2,
  pan[1] + height/scale/2
  ];

  svgG.transition().ease("linear").attr("transform",
    "scale(" + scale + ") "
    + "translate(" + translate + ")");
}

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
      svgG.selectAll(".node").attr("r", function(d_1) {
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

   });
