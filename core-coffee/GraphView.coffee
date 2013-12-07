# renders the graph using d3's force directed layout
define [], () ->

  class LinkFilter extends Backbone.Model
    initialize: () ->
      @set "threshold", 0.75
    filter: (links) ->
      return _.filter links, (link) =>
        return link.strength > @get("threshold")
    connectivity: (value) ->
      if value
        @set("threshold", value)
      else
        @get("threshold")

  class GraphView extends Backbone.View

    init: (instances) ->
      @model = instances["GraphModel"]
      @model.on "change", @update.bind(this)
      @render()
      instances["Layout"].addCenter @el


    initialize: (options) ->
      # filter between model and visible graph
      # use identify function if not defined
      @linkFilter = new LinkFilter(this);
      @listenTo @linkFilter, "change:threshold", @update

    drawXHairs: (x,y,obj) ->
            obj.append("line")
            .attr("x1", x)
            .attr("x2", x)
            .attr("y1", y-10)
            .attr("y2", y+10)
            .attr("stroke-width", 2)
            .attr("stroke", "red");
            obj.append("line")
            .attr("x1", x+10)
            .attr("x2", x-10)
            .attr("y1", y)
            .attr("y2", y)
            .attr("stroke-width", 2)
            .attr("stroke", "red")


    render: ->
      initialWindowWidth = $(window).width()
      initialWindowHeight = $(window).height()
      @force = d3.layout.force()
        .size([initialWindowWidth, initialWindowHeight])
        .charge(-500)
        .gravity(0.2)
      @linkStrength = (link) =>
        return (link.strength - @linkFilter.get("threshold")) / (1.0 - @linkFilter.get("threshold"))
      @force.linkStrength @linkStrength
      svg = d3.select(@el).append("svg:svg").attr("pointer-events", "all")
      zoom = d3.behavior.zoom()

      # create arrowhead definitions
      defs = svg.append("defs")

      defs
        .append("marker")
        .attr("id", "Triangle")
        .attr("viewBox", "0 0 20 15")
        .attr("refX", "15")
        .attr("refY", "5")
        .attr("markerUnits", "userSpaceOnUse")
        .attr("markerWidth", "20")
        .attr("markerHeight", "15")
        .attr("orient", "auto")
        .append("path")
          .attr("d", "M 0 0 L 10 5 L 0 10 z")

      defs
        .append("marker")
        .attr("id", "Triangle2")
        .attr("viewBox", "0 0 20 15")
        .attr("refX", "-5")
        .attr("refY", "5")
        .attr("markerUnits", "userSpaceOnUse")
        .attr("markerWidth", "20")
        .attr("markerHeight", "15")
        .attr("orient", "auto")
        .append("path")
          .attr("d", "M 10 0 L 0 5 L 10 10 z")

      # outermost wrapper - this is used to capture all zoom events
      zoomCapture = svg.append("g")

      # this is in the background to capture events not on any node
      # should be added first so appended nodes appear above this
      zoomCapture.append("svg:rect")
             .attr("width", "100%")
             .attr("height", "100%")
             .style("fill-opacity", "0%")

      # lock infrastracture to ignore zoom changes that would
      # typically occur when dragging a node
      translateLock = false
      currentZoom = undefined
      @force.drag().on "dragstart", ->
        translateLock = true
        currentZoom = zoom.translate()
      .on "dragend", ->
        zoom.translate currentZoom
        translateLock = false

      # add event listener to actually affect UI

      # ignore zoom event if it's due to a node being dragged

      # otherwise, translate and scale according to zoom
      ###
      #disabled dragging for clicking
      zoomCapture.call(zoom.on("zoom", -> # ignore double click to zoom
        return  if translateLock
        workspace.attr "transform", "translate(#{d3.event.translate}) scale(#{d3.event.scale})"
      )).on("dblclick.zoom", null)
###
      # inner workspace which nodes and links go on
      # scaling and transforming are abstracted away from this
      workspace = zoomCapture.append("svg:g")


      #Click Scrolling
      width = $("#maingraph").width()
      height = $("#maingraph").height() 

      @drawXHairs(width/2,height/2,zoomCapture);
      translateParams=[0,0]
      
      zoomCapture.on "click", ->
        # translateLock = true
        x = d3.mouse(this)[0]
        y = d3.mouse(this)[1]
        scale = zoom.scale()


        #translateParams = [x + width/scale/2,y + height/scale/2]
        translateParams = [translateParams[0]+width/scale/2 -x,translateParams[1]+height/scale/2-y]
        
        console.log(width,height,x,y,scale,translateParams)
        workspace.transition().ease("linear").attr "transform", "translate(#{translateParams}) scale(#{scale})"
      




      #Edge Scrolling
      self = this;

      edgeScrollVect=[0,0]
      edgeScrollSpeed=10

      ScrollTimer = ""
      @StartScroll = () ->
          ScrollTimer = window.setInterval( () ->
              translateParams = [translateParams[0]+edgeScrollSpeed*edgeScrollVect[0],translateParams[1]+edgeScrollSpeed*edgeScrollVect[1]]
              scale = zoom.scale()
              workspace.transition().ease("linear").attr "transform", "translate(#{translateParams}) scale(#{scale})"
          , 10)

      

      @StopScroll = () ->
          if ScrollTimer != ""
              window.clearInterval(ScrollTimer)
        
      ###// to scroll the div when the mouse mouse at the bottom right corner
      canvas.mousemove(function(event) {
          self.StopScroll();
          var boundaries = canvas[0].getBoundingClientRect();
          //-50 margin, so that we can scroll the div when the mouse at the bottom right corner.
          if (event.offsetX > boundaries.width - 50) {
              self.StartScroll()
          }
      });
      // stop scroll when the mouse is out of the div 
      canvas.mouseout(function(event) {
          self.StopScroll();
      });###
      zoomCapture.on "mouseout", () ->
              self.StopScroll()
              self.blur()
              $("body").css("cursor","inherit")              
          
      zoomCapture.on "mousemove", () ->
        self.StopScroll()
        edgeScrollVect=[0,0]

        margin=20;
        
        x=d3.mouse(this)[0]
        y=d3.mouse(this)[1]

        if x < margin
          edgeScrollVect[0]=1
        else if width-x < margin
          edgeScrollVect[0]=-1
        else if y < margin
          edgeScrollVect[1]=1
        else if height-y < margin
          edgeScrollVect[1]=-1

        else
          $("body").css("cursor","inherit") 
          return

        $("body").css("cursor","move")              
        self.StartScroll()
        console.log(x,y,width,height,edgeScrollVect)
        ###
        
        boundaries = workspace.getBoundingClientRect()
        #//-50 margin, so that we can scroll the div when the mouse at the bottom right corner.
        if (event.offsetX > boundaries.width - 50) {
            self.StartScroll()
        }


        # translateLock = true
        x = d3.mouse(this)[0]
        y = d3.mouse(this)[1]
        scale = zoom.scale()


        #translateParams = [x + width/scale/2,y + height/scale/2]
        translateParams = [translateParams[0]+width/scale/2 -x,translateParams[1]+height/scale/2-y]
        
        console.log(width,height,x,y,scale,translateParams)
        workspace.transition().ease("linear").attr "transform", "translate(#{translateParams}) scale(#{scale})"
        ###


      # containers to house nodes and links
      # so that nodes always appear above links
      linkContainer = workspace.append("svg:g").classed("linkContainer", true)
      nodeContainer = workspace.append("svg:g").classed("nodeContainer", true)
      return this

    update: ->
      nodes = @model.get("nodes")
      links = @model.get("links")
      filteredLinks = if @linkFilter then @linkFilter.filter(links) else links
      @force.nodes(nodes).links(filteredLinks).start()
      link = @linkSelection = d3.select(@el).select(".linkContainer").selectAll(".link").data(filteredLinks, @model.get("linkHash"))
      linkEnter = link.enter().append("line")
        .attr("class", "link")
        .attr 'marker-end', (link) ->
          'url(#Triangle)' if link.direction is 'forward' or link.direction is 'bidirectional'
        .attr 'marker-start', (link) ->
          'url(#Triangle2)' if link.direction is 'backward' or link.direction is 'bidirectional'
      @force.start()
      link.exit().remove()
      link.attr "stroke-width", (link) => 5 * (@linkStrength link)
      node = @nodeSelection = d3.select(@el).select(".nodeContainer").selectAll(".node").data(nodes, @model.get("nodeHash"))
      nodeEnter = node.enter().append("g").attr("class", "node").call(@force.drag)
      nodeEnter.append("text")
           .attr("dx", 12)
           .attr("dy", ".35em")
           .text((d) ->
            d.text
          )

      nodeEnter.append("circle")
           .attr("r", 5)
           .attr("cx", 0)
           .attr("cy", 0)

      @trigger "enter:node", nodeEnter
      @trigger "enter:link", linkEnter
      node.exit().remove()
      @force.on "tick", ->
        link.attr("x1", (d) ->
          d.source.x
        ).attr("y1", (d) ->
          d.source.y
        ).attr("x2", (d) ->
          d.target.x
        ).attr("y2", (d) ->
          d.target.y
        )

        node.attr "transform", (d) ->
          "translate(#{d.x},#{d.y})"

    getNodeSelection: ->
      return @nodeSelection

    getLinkSelection: ->
      return @linkSelection

    getForceLayout: ->
      return @force

    getLinkFilter: ->
      return @linkFilter