/* get original dimensions to center first animation */
var initialWindowWidth = $(window).width();
var initialWindowHeight = $(window).height();

var force = d3.layout.force()
    .linkStrength(function(d) { return (d.strength  - 0.75) / (1 - 0.75); })
    .size([initialWindowWidth, initialWindowHeight])

function registerInput(workspace) {
  $("#input-search").keypress(function(e) {

    var val = $("#input-search").val();
    if (e.which === 13 && val.length > 0) {
      $.ajax({
        url: "/get_data",
        type: "GET",
        data: {text: val},
        success: function(response) {
          render(workspace, response.nodes, response.links);
        },
        error: function(response) {
          alert(val + " was not found as a concept. Please try something else.");
        },
      });
    }
  });
}

/* link d3 parameter controls so changes render in real time */
function registerForceControls() {

  var mappings = [
    {
      f: force.linkDistance,
      selector: "#input-link-distance",
      scale: d3.scale.linear()
        .domain([0, 200])
        .range([0, 100]),
    },

    {
      f: force.friction,
      selector: "#input-friction",
      scale: d3.scale.linear()
        .domain([.99, 0.5])
        .range([0, 100]),
    },

    {
      f: force.charge,
      selector: "#input-charge",
      scale: d3.scale.linear()
        .domain([0, -2000])
        .range([0, 100]),
    },

    {
      f: force.gravity,
      selector: "#input-gravity",
      scale: d3.scale.linear()
        .domain([0.01, 1])
        .range([0, 100]),
    },
  ]

  _.each(mappings, function(mapping) {
    $(mapping.selector)
      .val(mapping.scale(mapping.f()))
      .change(function() {
        mapping.f(mapping.scale.invert($(this).val()));
        force.start();
    });
  });
}

/* create and return zoomable workspace */
function createWorkspace() {
  
  // svg element which houses everything
  var svg = d3.select("#workspace")
    .append("svg:svg")
      .attr("pointer-events", "all")

  // zoom behavior which is used to scale and translate
  var zoom = d3.behavior.zoom();

  // outermost wrapper - this is used to capture all zoom events
  var zoomCapture = svg.append('g')
      .classed('zoom-capture', true);

  // this is in the background to capture events not on any node  
  // should be added first so appended nodes appear above this
  var rect = zoomCapture.append('svg:rect')
    .attr("width", "100%")
    .attr("height", "100%")
    .attr("fill", "red")
    .style("fill-opacity", "0%");

  // inner workspace which nodes and links go on
  // scaling and transforming are abstracted away from this
  var workspace = zoomCapture.append('svg:g');
  
  // lock infstracture to ignore zoom changes that would
  // typically occur when dragging a node
  var translateLock = false;
  var currentZoom;
  force.drag()
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
  }));

  return workspace;
}

/* establish how data is to be rendered - bind elements to force layout */
function render(svg, nodes, links) {

  $(".node, .link").remove();

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

  var workspace = createWorkspace();
  registerInput(workspace);
  registerForceControls();

});