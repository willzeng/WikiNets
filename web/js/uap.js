/* get original dimensions to center first animation */
var initialWindowWidth = $(window).width();
var initialWindowHeight = $(window).height();

/* every change should be channeled through here */
function Controller(selector) {

  // handle keypresses
  (function() {

    // handle combinations of keypresses
    var altKey = 18,
        ctrlKey = 17,
        altDown = false,
        ctrlDown = false;

    var ctrlDown, altDown;

    $(window).keydown(function(e) {

      // only except elements when body is the target
      // this ignores keypresses from inputs, for example
      if (e.target !== document.querySelector("body")) return;

      if (e.which === altKey) { altDown = true; }
      if (e.which === ctrlKey) { ctrlDown = true; }

      // ESC ==> deselect all
      if (e.which === 27) {
        this.deselectAll();
      }

      // DELETE ==> remove selection
      if (e.which === 46) {
        this.removeSelection();
      }

      // ENTER ==> remove unselected
      if (e.which === 13) {
        this.removeCompliment();
      }

      // / ==> give search focus
      if (e.which === 191) {
        $("#input-search").focus();
        e.preventDefault();
      }

      // Ctrl + A ==> select all nodes
      if (ctrlDown && e.which === 65) {
        this.selectAll();
        e.preventDefault();
      }

      // + ==> add related nodes
      if (e.which === 187) {
        this.addRelatedConcepts();
        e.preventDefault();
      }

    }.bind(this))
    .keyup(function(e) {
      if (e.target !== document.querySelector("body")) return;

      if (e.which === altKey) { altDown = false; }
      if (e.which === ctrlKey) { ctrlDown = false; }
    }.bind(this));
  }.bind(this))();

  // block normal contextmenus so custom one works
  $(window).on("contextmenu",function(e) {e.preventDefault(); });

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
  var edgeContainer = workspace.append('svg:g')
  var nodeContainer = workspace.append('svg:g')
  
  /* EVERYTHING SHOULD BE *LINKS* AND *NODES* */

  var nodes = [];

  var allLinks = [];
  var renderedLinks = [];

  var minStrength = 0.75;

  /* instantiate global force object */
  var force = d3.layout.force()
    .linkStrength(function(d) { return (d.strength  - minStrength) / (1 - minStrength); })
    .size([initialWindowWidth, initialWindowHeight])
  this.force = force;

  // define key functions
  function getNodeKey(d) {
    return d.text;
  }

  function getLinkKey(l) {
    var sourceKey = getNodeKey(l.source);
    var targetKey = getNodeKey(l.target);
    return sourceKey + targetKey;
  }

  this.updateRendering = function() {

    // update force layout
    this.force
      .nodes(nodes)
      .links(renderedLinks)
      .start()

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
    }))
    .on("dblclick.zoom", null); // ignore double click to zoom

    // update links
    var link = edgeContainer.selectAll(".link")
        .data(renderedLinks, getLinkKey);

    link.enter().append("line")
      .attr("class", "link");

    link.exit().remove();

    // update nodes
    var node = nodeContainer.selectAll(".node")
      .data(nodes, getNodeKey);

    var controller = this; // lame, but need default `this`
    var clickSemaphore = 0;
    var nodeEnter = node.enter().append("g")
      .attr("class", "node")
      .call(force.drag)
      .on('click', function(datum, index) {
        if (d3.event.defaultPrevented) return; // ignore drag
        datum.fixed = true;
        clickSemaphore += 1;
        var savedClickSemaphore = clickSemaphore;
        setTimeout(function() {
          if (clickSemaphore === savedClickSemaphore) {
            controller.toggleSelected(datum);
            datum.fixed = false;
          } else {
            // increment so second click isn't registered as a click
            clickSemaphore += 1;
            datum.fixed = false;
          }
        }, 250);
        
      })
      .on('dblclick', function(datum, index) {
        controller.selectConnectedComponent(datum);
      });
      
    nodeEnter.append("text")
      .attr("dx", 12)
      .attr("dy", ".35em")
      .text(function(d) { return d.text; });

    nodeEnter.append("circle")
      .attr("r", 5)
      .attr("cx", 0)
      .attr("cy", 0);

    node.classed('selected', function(d) {return d.selected; });

    node.exit().remove();

    // reaffirm how rendering is done

    force.on("tick", function() {
      link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; })
        .style("stroke-width", function(d) {
          return 5 * (d.strength - minStrength) / (1 - minStrength)
        });

      node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
      
    });

    // show or hide helper
    if (_.some(nodes, function(n) {return n.selected; })) {
      $("#selection-helper").fadeIn();
    } else {
      $("#selection-helper").fadeOut();
    }

    // update stats
    $("#stat-num-nodes").text(nodes.length);
  };

  this.renderSelection = function() {
    nodeContainer.selectAll(".node").classed('selected', function(d) {return d.selected; });
  }

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
        var node = {text: text, selected: true};
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

  this.removeSelection = function() {

    // remove any edges associated with those nodes
    function shouldKeep(link) {
      return !link.source.selected && !link.target.selected;
    }

    allLinks = _.filter(allLinks, shouldKeep);
    renderedLinks = _.filter(renderedLinks, shouldKeep);

    // remove all nodes
    nodes = _.filter(nodes, function(node) { return !node.selected; });

    // update ui
    this.updateRendering();
  }

  this.removeCompliment = function() {
    function shouldKeep(link) {
      return link.source.selected && link.target.selected;
    }

    allLinks = _.filter(allLinks, shouldKeep);
    renderedLinks = _.filter(renderedLinks, shouldKeep);

    // remove all nodes
    nodes = _.filter(nodes, function(node) { return node.selected; });

    // update ui
    this.updateRendering();
  }

  this.toggleSelected = function(d) {
    d.selected = !d.selected;
    this.renderSelection();
  };

  this.selectNeighbors = function() {
    _.chain(nodes).filter(function(n) {
      return n.selected;
    }).each(function(n) {
      _.each(renderedLinks, function(link) {
        if (link.source === n) {
          link.target.selected = true;
        }
        if (link.target === n) {
          link.source.selected = true;
        }
      });
    });
    this.renderSelection();
  }

  this.selectAll = function() {
    _.each(nodes, function(node) {
      node.selected = true;
    });
    this.renderSelection();
  }

  this.deselectAll = function() {
    _.each(nodes, function(node) {
      node.selected = false;
    });
    this.renderSelection();
  }

  this.addRelatedConcepts = function() {
    var selectedConceptNames = _.chain(nodes)
      .filter(function(n) { return n.selected; })
      .map(function(n) { return n.text; })
      .value();

    var allConceptNames = _.map(nodes, function(n) {
      return n.text;
    });

    $.ajax({
      url: "/get_related_concepts",
      data: {
        selectedConcepts: JSON.stringify(selectedConceptNames), 
        allConcepts: JSON.stringify(allConceptNames),
        minStrength: minStrength,
      },
      success: function(response) {
        /************************
        response.nodes
          list of new concept names not already in graph
        response.crossLinks
          list of link objects with
            strength: \in [0,1]
            source: index into nodes
            target: index into response.nodes
        response.selfLinks
          list of link objects with
            strength: \in [0,1]
            source: index into response.nodes
            target: index into response.nodes
        *************************/
        // create list of actual node objects which force will manipulate
        var newNodes = _.map(response.nodes, function(newConcept) {
          return {text: newConcept, selected: true};
        });
        // add new nodes to list of nodes
        _.each(newNodes, function(newNode) {
          nodes.push(newNode);
        });
        // add cross links
        _.each(response.crossLinks, function(crossLink) {
          var newLink = {
            strength: crossLink.strength,
            source: nodes[crossLink.source],
            target: newNodes[crossLink.target],
          }
          allLinks.push(newLink);
          if (newLink.strength > minStrength) {
            renderedLinks.push(newLink);
          }
        });
        // add self links
        _.each(response.selfLinks, function(selfLink) {
          var newLink = {
            strength: selfLink.strength,
            source: newNodes[selfLink.source],
            target: newNodes[selfLink.target],
          };
          allLinks.push(newLink);
          if (newLink.strength > minStrength) {
            renderedLinks.push(newLink);
          }
        });
        // show in ui
        this.updateRendering();
      }.bind(this),
    })
  }

  this.setMinStrength = function(value) {
    minStrength = value;
    renderedLinks = _.filter(allLinks, function(link) {
      return link.strength > minStrength;
    });
    this.updateRendering();
  }

  this.getMinStrength = function() {
    return minStrength;
  }

  this.selectConnectedComponent = function(node) {
    var queue = [node];
    var graph = {};
    var lookup = {};
    _.each(nodes, function(node) {
      graph[node.text] = {};
      lookup[node.text] = node;
    });
    _.each(renderedLinks, function(link) {
      graph[link.source.text][link.target.text] = 1;
      graph[link.target.text][link.source.text] = 1;
    });
    var seen = {};
    function visit(text) {
      if (!_.has(seen, text)) {
        seen[text] = 1;
        _.each(graph[text], function(ignore, neighborText) {
          visit(neighborText);
        }); 
      }
    }
    visit(node.text);
    var allTrue = true;
    _.each(seen, function(ignore, text) {
      allTrue = allTrue && lookup[text].selected;
    });
    var newSelected = !allTrue;
    _.each(seen, function(ignore, text) {
      lookup[text].selected = newSelected;
    });
    this.renderSelection();
  }
}

/* capture searches */
function registerConceptSearch(controller) {
  $("#input-search").typeahead({
    prefetch: '/get_concepts',
    name: "concepts",
    limit: 100,
  }).on("typeahead:selected", function(e, datum) {
    controller.addConcept(datum.value);
    $(this).blur();
  });
}

/* link d3 parameter controls so changes render in real time */
function registerForceControls(controller) {

  var mappings = [

    {
      f: controller.force.charge,
      selector: "#input-charge",
      scale: d3.scale.linear()
        .domain([0, -2000])
        .range([0, 100]),
    },

    {
      f: controller.force.gravity,
      selector: "#input-gravity",
      scale: d3.scale.linear()
        .domain([0.01, 1])
        .range([0, 100]),
    },

    {
      f: function(value) {
        if (value) {
          controller.setMinStrength(value);
        } else {
          return controller.getMinStrength();
        }
      },
      selector: "#input-min-edge-weight",
      scale: d3.scale.log()
        .domain([0.75, 1])
        .range([100, 0]),
    },
  ]

  _.each(mappings, function(mapping) {
    $(mapping.selector)
      .val(mapping.scale(mapping.f()))
      .change(function() {
        mapping.f(mapping.scale.invert($(this).val()));
        controller.force.start();
    });
  });
}

function registerSelectionControls(controller) {
  
  $("#btn-add-related-concepts").click(function() {
    controller.addRelatedConcepts();
  });

}

/* on page load */
$(function() {
  var controller = new Controller("#workspace");
  registerConceptSearch(controller);
  registerForceControls(controller);
  registerSelectionControls(controller);
  $("#input-search").focus();
});