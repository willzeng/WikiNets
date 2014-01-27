# provides a minimap showing the neighbors of the node most recently clicked on
define [], () ->

  class MiniMap extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->    
      @graphView = instances['GraphView']
      @graphView.on("enter:node:click", (datum) =>
        @chooseCenter(datum)
        )

      @model = instances["GraphModel"]
      @model.on "change", @update.bind(this)

      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)
      
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'MiniMap', true

      @render()


    render: ->
      @miniMapWidth = 200
      @miniMapHeight = 200

      # workspace which the minimap will go on
      @frame = d3.select(@el).append("svg:svg").attr("width", @miniMapWidth)
                .attr("height", @miniMapHeight);

      return this


    update: ->
      #Clear the workspace and setup a new one
      @$el.empty()
      @frame = d3.select(@el).append("svg:svg").attr("width", @miniMapWidth)
                .attr("height", @miniMapHeight)

      if (@mostRecentNode isnt undefined) and (@mostRecentNode in @model.getNodes())

        centerID = @model.get("nodeHash")(@mostRecentNode)
    
        #Find the list of neighbors only using links of non-zero strength
        allLinks = (link for link in @model.getLinks() when link.strength > 0)

        #Find neighbors with arrows directed out
        neighbors = (link.target for link in allLinks when @model.get("nodeHash")(link.source) is centerID)
        
        #Add neighbors with arrows directed in
        neighbors.push link.source for link in allLinks when @model.get("nodeHash")(link.target) is centerID
        
        # This is the width of the center node of the minimap
        central_width=14;
        # The radius of the circle for each neighbor
        circle_sizer=10;
        # padding around the minimap
        minimap_padding = 5;
        # scales the size of the minimap to match the framesize
        minimap_scalar = @miniMapWidth/2-central_width/2-circle_sizer-minimap_padding;

        #font size of the minimap text labels
        minimap_text_size=14; 

        sub_width = @miniMapWidth
        sub_height = @miniMapHeight

        #Draws the spokes out from the central node in the minimap  
        if neighbors.length > 0
          @frame.append("line")
            .attr("x1", sub_width/2+central_width/2)
            .attr("y1", sub_height/2+central_width/2)
            .attr("x2", minimap_scalar*Math.sin(2*k*Math.PI/neighbors.length)+sub_width/2+central_width/2)
            .attr("y2", minimap_scalar*Math.cos(2*k*Math.PI/neighbors.length)+sub_height/2+central_width/2)
            .style("stroke", "lightgrey")
            .style("stroke-width", "2")
            .on("click", (d_2, i_2) ->
              # Need to add actual functionality here once it's available
              alert("You clicked a link!", d_2, i_2)
            ) for k in [0..(neighbors.length-1)]
            ### should eventually implement directed arrows here ###
            #.attr("marker-end", "url(#subNetTriangle)")

        #Draws the central node in the minimap as a light blue square
        @frame.append("circle")
              .attr("class", "node")
              .attr("stroke", "darkgrey")
              .attr("stroke-width", 3)
              .attr("fill", if @mostRecentNode.selected then "steelblue" else "white")
              .attr("cx", sub_width/2+central_width/2).attr("cy", sub_height/2+central_width/2).attr("r", central_width)
              .on("click", () =>
                @selection.toggleSelection(@mostRecentNode)
              )

        #Draws the neighbors in the minimap as red circles
        if neighbors.length > 0
          for k in [0..(neighbors.length-1)]
            @frame.append("circle")
              .attr("class", "node")
              .attr("r", circle_sizer)
              .attr("stroke", "darkgrey")
              .attr("stroke-width", 3)
              .attr("fill", if neighbors[k].selected then "steelblue" else "white")
              .attr("cx", minimap_scalar*Math.sin(2*k*Math.PI/neighbors.length)+sub_width/2+central_width/2)
              .attr("cy",  minimap_scalar*Math.cos(2*k*Math.PI/neighbors.length)+sub_height/2+central_width/2)
              .data([neighbors[k]])
              .on("click", (node) =>
                if @mostRecentNode.selected and !d3.event.shiftKey and !d3.event.ctrlKey then @selection.toggleSelection(@mostRecentNode)
                @selection.toggleSelection(node)
                if !d3.event.shiftKey then @chooseCenter(node)
              ) 

        #Draws the text labels on the neighors in the minimap
        if neighbors.length > 0
          @frame.append("text")
              .attr("fill", "black")
              .attr("font-size", minimap_text_size)
              .attr("x", minimap_scalar*Math.sin(2*k*Math.PI/neighbors.length)+sub_width/2+16)
              .attr("y", minimap_scalar*Math.cos(2*k*Math.PI/neighbors.length)+sub_height/2+central_width/2-12)
              .text( @findHeader(neighbors[k])
              ) for k in [0..(neighbors.length-1)]


        #Draws the text label on the central node in the minimap
        @frame.append("text")
            .attr("fill", "black")
            .attr("font-size", minimap_text_size)
            .attr("x", sub_width/2+16)
            .attr("y", sub_height/2-1+central_width/2-12)
            .text(@findHeader(@mostRecentNode))

    chooseCenter: (node)->
      @mostRecentNode = node
      @update()

    findHeader: (node) ->
      if node.name?
        node.name
      else if node.title?
        node.title
      else
        ''
