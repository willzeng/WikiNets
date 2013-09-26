
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

      // this ignores keypresses from inputs
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
        this.removeSelectionCompliment();
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
        this.addRelatedNodes();
        e.preventDefault();
      }

    }.bind(this))
    .keyup(function(e) {

      // this ignores keypresses from inputs
      if (e.target !== document.querySelector("body")) return;

      // update state of combination keys
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

  // containers to house nodes and edges
  // so that nodes always appear above edges
  var edgeContainer = workspace.append('svg:g')
  var nodeContainer = workspace.append('svg:g')
  
  /* EVERYTHING SHOULD BE *LINKS* AND *NODES* */

  // list of nodes which force layout mutates
  var nodes = [];

  // list of all links
  var allLinks = [];

  // links of shown links which force layout mutates
  var renderedLinks = [];

  // current edge weight threshold for deciding if link should be shown
  var minThreshold = this.minThreshold = 0.75;
  var currentLinkStrengthThreshold = 1.0;



  // global force object
  var force = d3.layout.force()
    .linkStrength(function(d) { return (d.strength  - currentLinkStrengthThreshold) / (1 - currentLinkStrengthThreshold); })
    .size([initialWindowWidth, initialWindowHeight])
  this.force = force;

  /******************************************************************
   define key functions for data

  this allows d3 to bind reordered data to the same DOM elements
  ******************************************************************/

  // define key functions for node data
  function getNodeKey(d) {
    return d.text;
  }

  // define key funciton for link data
  function getLinkKey(l) {
    var sourceKey = getNodeKey(l.source);
    var targetKey = getNodeKey(l.target);
    return sourceKey + targetKey;
  }

  // update which nodes and edges are displayed
  // should be called after changes to those lists
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

    // add new links
    link.enter().append("line")
      .attr("class", "link");

    // remove links which no longer exist
    link.exit().remove();

    // update nodes
    var node = nodeContainer.selectAll(".node")
      .data(nodes, getNodeKey);

    // differentiate between single and double click
    var clickSemaphore = 0;

    // add new nodes as svg:g elements
    // this allows housing arbitrary content within each node
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
            this.toggle(datum);
            datum.fixed = false;
          } else {
            // increment so second click isn't registered as a click
            clickSemaphore += 1;
            datum.fixed = false;
          }
        }.bind(this), 250);
        
      }.bind(this))
      .on('dblclick', function(datum, index) {
        this.selectConnectedComponent(datum);
      }.bind(this));
      
    // add label
    nodeEnter.append("text")
      .attr("dx", 12)
      .attr("dy", ".35em")
      .text(function(d) { return d.text; });

    // add actual node
    nodeEnter.append("circle")
      .attr("r", 5)
      .attr("cx", 0)
      .attr("cy", 0);

    // render as selected or not
    this.renderSelection();

    // remove  nodes which no longer exist
    node.exit().remove();

    // update force event listener to handle updated element selections
    force.on("tick", function() {
      link
        .attr("x1", function(d) { return d.source.x; })
        .attr("y1", function(d) { return d.source.y; })
        .attr("x2", function(d) { return d.target.x; })
        .attr("y2", function(d) { return d.target.y; })
        .style("stroke-width", function(d) {
          // scale width based on strength, where
          //   barely hitting Connectivity threshold ==> 0
          //   1 ==> 1
          // provides fluid entrance of new edges
          return 4 * (d.strength - currentLinkStrengthThreshold) / (1 - currentLinkStrengthThreshold);
        });
      node.attr("transform", function(d) { 
        return "translate(" + d.x + "," + d.y + ")"; 
      });
    });

    // update Stats Helper
    $("#stat-num-nodes").text(nodes.length);
    $("#stat-num-edges").text(renderedLinks.length);
  };

  // update only which nodes are selected
  // does NOT restart force layout
  this.renderSelection = function() {
    // give nodes correct class based on selection
    nodeContainer.selectAll(".node")
      .classed('selected', function(d) {
        return d.selected; 
      });
    // show or hide selection helper
    if (_.some(nodes, function(n) {return n.selected; })) {
      $("#selection-helper").fadeIn();
    } else {
      $("#selection-helper").fadeOut();
    }
  }

  // add node with text to graph
  this.addNode = function(text) {

    // if node already present, ignore
    var presentNode = _.find(nodes, function(node) {
      return node.text === text;
    });
    if (presentNode) return;

    // capture array of other node names
    var otherNodes = _.map(nodes, function(node) {
      return node.text;
    });

    var note = new Notification();
    note.setText("Loading: " + text + "...");
    note.show();
    
    // make AJAX request
    $.ajax({
      url: "get_edges",
      data: {text: text, allNodes: JSON.stringify(otherNodes)},

      // expects array of strengths
      success: function(response) {  
        // add new node to data
        var node = {text: text, selected: true};
        nodes.push(node);

        // add new links to data
        _.each(response, function(strength, i) {
          var link = {source: node, target: nodes[i], strength: strength};
          allLinks.push(link);
          if (strength > currentLinkStrengthThreshold) {
            renderedLinks.push(link);
          }
        });

        // update UI
        note.remove();
        this.updateRendering();
      }.bind(this),
      error: function(response) {
        console.log(response);
        note.addText("Error Encountered.");
        setTimeout(note.remove, 5000);
      }
    });
  };

  // removes currently selected nodes
  this.removeSelection = function() {

    // filter to remove any edges associated with those nodes
    function shouldKeep(link) {
      return !link.source.selected && !link.target.selected;
    }
    allLinks = _.filter(allLinks, shouldKeep);
    renderedLinks = _.filter(renderedLinks, shouldKeep);

    // remove all selected nodes
    nodes = _.filter(nodes, function(node) { return !node.selected; });

    // update ui
    this.updateRendering();
  }

  // removes all unselected nodes
  this.removeSelectionCompliment = function() {

    // filter to remove any edges to unselected nodes
    function shouldKeep(link) {
      return link.source.selected && link.target.selected;
    }
    allLinks = _.filter(allLinks, shouldKeep);
    renderedLinks = _.filter(renderedLinks, shouldKeep);

    // remove all unselected nodes
    nodes = _.filter(nodes, function(node) { return node.selected; });

    // update ui
    this.updateRendering();
  }

  // toggles selection of node
  this.toggle = function(node) {
    node.selected = !node.selected;
    this.renderSelection();
  };

  // selects all nodes
  this.selectAll = function() {
    _.each(nodes, function(node) {
      node.selected = true;
    });
    this.renderSelection();
  }

  // deselects all nodes
  this.deselectAll = function() {
    _.each(nodes, function(node) {
      node.selected = false;
    });
    this.renderSelection();
  }

  // adds nodes related to currently selected nodes
  // st. all new nodes have edge to currently selected 
  // meeting current Connectivity threshold
  this.addRelatedNodes = function() {
    var selectedNodeNames = _.chain(nodes)
      .filter(function(n) { return n.selected; })
      .map(function(n) { return n.text; })
      .value();

    // gather all node names
    var allNodeNames = _.map(nodes, function(n) {
      return n.text;
    });

    // create notification
    var note = new Notification();
    note.setText("Retreiving related nodes...");
    note.show();

    // request new data
    $.ajax({
      url: "/get_related_nodes",
      data: {
        selectedNodes: JSON.stringify(selectedNodeNames), 
        allNodes: JSON.stringify(allNodeNames),
        minStrength: minThreshold,
      },
      success: function(response) {
        
        /************************************************************
        response.nodes
          list of new node names not already in graph
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
        ************************************************************/

        // create list of actual node objects which force will manipulate
        var newNodes = _.map(response.nodes, function(newNode) {
          return {text: newNode, selected: true};
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
          if (newLink.strength > currentLinkStrengthThreshold) {
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
          if (newLink.strength > currentLinkStrengthThreshold) {
            renderedLinks.push(newLink);
          }
        });

        // show in UI
        if (response.nodes.length === 0) {
          note.addText("No nodes added.");
          setTimeout(note.remove, 3000);
        } else {
          note.remove();
        }
        this.updateRendering();
      }.bind(this),
      error: function(response) {
        note.addText("Error Encountered.");
        setTimeout(note.remove, 5000);
      }
    })
  }

  // set Connectivity minimum strength threshold
  this.setCurrentLinkStrengthThreshold = function(value) {
    currentLinkStrengthThreshold = value;
    renderedLinks = _.filter(allLinks, function(link) {
      return link.strength > currentLinkStrengthThreshold;
    });
    this.updateRendering();
  }

  // get Connectivity minimum strength threshold
  this.getCurrentLinkStrengthThreshold = function() {
    return currentLinkStrengthThreshold;
  }

  // select all nodes which have a path to node
  // using edges meeting current Connectivity criteria
  this.selectConnectedComponent = function(node) {

    // create adjacency list version of graph
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

    // perform DFS to compile connected component
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

    // toggle selection appropriately
    // selection before ==> selection after
    //             none ==> all
    //             some ==> all
    //             all  ==> none
    var allTrue = true;
    _.each(seen, function(ignore, text) {
      allTrue = allTrue && lookup[text].selected;
    });
    var newSelected = !allTrue;
    _.each(seen, function(ignore, text) {
      lookup[text].selected = newSelected;
    });

    // update UI
    this.renderSelection();
  }
}

/* handle user input in node search helper */
function registerNodeSearch(controller) {
  $("#input-search").typeahead({
    prefetch: '/get_nodes',
    name: "nodes",
    limit: 100,
  }).on("typeahead:selected", function(e, datum) {
    controller.addNode(datum.value);
    $(this).blur();
  });
}

/* handle user input in layout helper */
function registerForceControls(controller) {

  // define mappings between values in code and values in UI
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
        .domain([0.01, 0.5])
        .range([0, 100]),
    },

    {
      f: function(value) {
        if (value) {
          controller.setCurrentLinkStrengthThreshold(value);
        } else {
          return controller.getCurrentLinkStrengthThreshold();
        }
      },
      selector: "#input-min-edge-weight",
      scale: d3.scale.log()
        .domain([controller.minThreshold, 1])
        .range([100, 0]),
    },
  ]

  // hook mappings up to respond to user input
  _.each(mappings, function(mapping) {
    $(mapping.selector)
      .val(mapping.scale(mapping.f()))
      .change(function() {
        mapping.f(mapping.scale.invert($(this).val()));
        controller.force.start();
    });
  });
}

/* handle user input for selection helper */
function registerSelectionControls(controller) {
  $("#btn-add-related-nodes").click(function() {
    controller.addRelatedNodes();
  });
}

/* make external links open in new tab */
function forceLinksToNewTab() {
  $(".external-link").click(function(e) {
    window.open($(this).attr("href"));
    e.preventDefault();
  });
}

function Notification() {
  
  var $el = $('<div class="notification"></div>');
  var removed = false;

  this.setText = function(text) {
    $el.text(text);
  }

  this.addText = function(text) {
    $el.text($el.text() + " " + text);
  }

  this.show = function() {
    setTimeout(function() {
      if (!removed) {
        $el.appendTo($("#notifications-container"))
        .hide().fadeIn(100);  
      }
    }, 100);
  }

  this.remove = function() {
    removed = true;
    $el.slideUp(100, $el.remove);
  }
}

/* on page load */
$(function() {
  forceLinksToNewTab();
  var controller = new Controller("#workspace");
  registerNodeSearch(controller);
  registerForceControls(controller);
  registerSelectionControls(controller);
  $("#input-search").focus();
});