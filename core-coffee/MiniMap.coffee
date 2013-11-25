# provides details of the selected nodes
define [], () ->

  class MiniMap extends Backbone.View

    init: (instances) ->
      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)
      instances["Layout"].addPlugin @el, 'MiniMap'
      @$el.toggle()
      
      @model = instances["GraphModel"]
      @model.on "change", @update.bind(this)
      @render()
      instances["Layout"].addCenter @el

    render: ->
      @miniMapWidth = 300
      @miniMapHeight = 300
      #svg = d3.select(@el).append("svg:svg").attr("pointer-events", "all")

      # inner workspace which the minimap will go on
      @frame = d3.select(@el).append("svg:svg").attr("width", @miniMapWidth)
                .attr("height", @miniMapHeight);

      # containers to house nodes and links
      # so that nodes always appear above links
      #linkContainer = workspace.append("svg:g").classed("linkContainer", true)
      #nodeContainer = workspace.append("svg:g").classed("nodeContainer", true)
      return this


    update: ->
      @$el.empty()
      @frame = d3.select(@el).append("svg:svg").attr("width", @miniMapWidth)
                .attr("height", @miniMapHeight);

      selectedNodes = @selection.getSelectedNodes()
      mostRecentSelectedNode = selectedNodes[selectedNodes.length - 1]

      console.log "center Node: ", mostRecentSelectedNode

      #Find the list of neighbors
      #console.log "nodes: ", @model.getNodes()
      #console.log "links: ", @model.getLinks()



      # This is the width of the center node of the subgraph
      central_width=20;
      # The radius of the circle for each neighbor
      circle_sizer=20;
      # padding around the drawn subgraph
      subgraph_padding = 30;
      # scales the size of the subgraph to match the framesize
      subgraph_scalar = @miniMapWidth/2-central_width/2-circle_sizer-subgraph_padding;
      # shift the entire graph to the left a bit
      shift_left = 30;



      ###
      Need
      ###
      

      ###
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
      _.each selectedNodes, (node) ->
        $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        $("<div class=\"node-profile-title\">#{node['text']}</div>").appendTo $nodeDiv
        _.each node, (value, property) ->
          $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0
      ###