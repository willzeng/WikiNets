/* get original dimensions to center first animation */
var initialWindowWidth = $(window).width();
var initialWindowHeight = $(window).height();

/* instantiate global force object */
var force = d3.layout.force()
    .linkStrength(function(d) { return (d.strength  - 0.75) / (1 - 0.75); })
    .size([initialWindowWidth, initialWindowHeight])

/* every change should be channeled through here */
function Controller(workspace) {
  
  var nodes = [];
  var selectedNodes = [];
  
  // these links always reference object in nodes
  var allLinks = [];
  var renderedLinks = [];
  

  var minStrength = 0.75;

  this.updateRendering = function() {
    
    // update force layout

    force
      .nodes(nodes)
      .links(renderedLinks)
      .start()

    // update links

    var link = workspace.selectAll(".link")
        .data(renderedLinks)

    link.enter().append("line")
      .attr("class", "link")
      .style("stroke-width", 1);  

    link.exit().remove();

    // update nodes

    var node = workspace.selectAll(".node")
      .data(nodes)

    var controller = this;

    var nodeEnter = node.enter().append("g")
      .attr("class", "node")
      .call(force.drag)
      .on('click', function(datum, index) {
        // `this` is current DOM element
        if (d3.event.defaultPrevented) return; // ignore drag
        controller.toggleSelected(datum);
        d3.select(this).classed("selected", function(d) {return d.selected; });
      })
      
    nodeEnter.append("text")
      .attr("dx", 12)
      .attr("dy", ".35em")
      .text(function(d) { return d.text; });

    nodeEnter.append("circle")
      .attr("r", 5)
      .attr("cx", 0)
      .attr("cy", 0);

    node.exit().remove();

    // reaffirm how rendering is done

    force.on("tick", function() {
      link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; });

      node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
      
    });
  };

  this.addConcept = function(text) {
    
    var presentNode = _.find(nodes, function(node) {
      return node.text === text;
    });

    if (presentNode) {
      return;
    }

    var otherConcepts = _.map(nodes, function(node) {
      return node.text;
    });
    
    $.ajax({
      url: "get_links",
      data: {text: text, allNodes: JSON.stringify(otherConcepts)},
      success: function(response) {
        // expects array of strengths
        var node = {text: text};
        nodes.push(node);
        _.each(response, function(strength, i) {
          var link = {source: node, target: nodes[i], strength: strength};
          allLinks.push(link);
          if (strength > minStrength) {
            renderedLinks.push(link);
          }
        });
        this.updateRendering();
      }.bind(this),
    });
  };

  this.select = function(d) {
    d.selected = true;
    selectedNodes.push(d);
  };

  this.toggleSelected = function(d) {
    d.selected = !d.selected;
    if (d.selected) {
      nodes[d.text] = d;
    } else {
      delete nodes[d.text];
    }
  }

}

/* capture searches */
function registerInput(controller) {
  $("#input-search").typeahead({
    prefetch: '/get_concepts',
    name: "concepts",
  }).on("typeahead:selected", function(e, datum) {
    $(this).val("");
    controller.addConcept(datum.value);
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

/* on page load */
$(function() {
  var workspace = createWorkspace();
  var controller = new Controller(workspace);
  registerInput(controller);
  registerForceControls();
});