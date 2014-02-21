# renders the graph using d3's force directed layout
define [], () ->

  class LinkFilter extends Backbone.Model
    initialize: () ->
      @set "threshold", 0
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
      @model.on "change", @update
      @render()
      #instances["Layout"].addCenter @el

      $(@el).appendTo $('#maingraph')

    initialize: (options) ->
      # filter between model and visible graph
      # use identify function if not defined
      @linkFilter = new LinkFilter(this);
      @listenTo @linkFilter, "change:threshold", @update

    render: ->
      initialWindowWidth = $(window).width()
      initialWindowHeight = $(window).height()
      @initialWindowWidth = initialWindowWidth
      @initialWindowHeight = initialWindowHeight
      @force = d3.layout.force()
        .size([initialWindowWidth, initialWindowHeight])
        .charge(-2000)
        .gravity(0.2)
      @linkStrength = (link) =>
        return (link.strength - @linkFilter.get("threshold")) / (1.0 - @linkFilter.get("threshold"))
      @force.linkStrength @linkStrength
      svg = d3.select(@el).append("svg:svg").attr("pointer-events", "all")
      zoom = d3.behavior.zoom()
      @zoom = zoom

      # create arrowhead definitions
      defs = svg.append("defs")

      defs
        .append("marker")
        .attr("id", "Triangle")
        .attr("viewBox", "0 0 20 15")
        .attr("refX", "20")
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

      gradient=defs.append("radialGradient");

      gradient
        .attr("id","gradFill")
        .attr("cx","50%")
        .attr("cy","50%")
        .attr("r","75%")
        .attr("fx","50%")
        .attr("fy","50%")
        .append("stop")
          .attr("offset","0%")
          .attr("style","stop-color:steelblue;stop-opacity:1");
      gradient
       .append("stop")
          .attr("offset","100%")
          .attr("style","stop-color:rgb(255,255,255);stop-opacity:1");


      # outermost wrapper - this is used to capture all zoom events
      zoomCapture = svg.append("g")

      # this is in the background to capture events not on any node
      # should be added first so appended nodes appear above this
      zoomCapture.append("svg:rect")
             .attr("width", "100%")
             .attr("height", "100%")
             .style("fill-opacity", "0%")
             .style("fill","white")

      # Panning on Drag
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
      # disabled dragging for clicking
      
      zoomCapture.call(zoom.on("zoom", -> # ignore double click to zoom
        return  if translateLock
        workspace.attr "transform", "translate(#{d3.event.translate}) scale(#{d3.event.scale})"
      )).on("dblclick.zoom", null)

      # inner workspace which nodes and links go on
      # scaling and transforming are abstracted away from this
      workspace = zoomCapture.append("svg:g")
      @workspace = workspace

      # containers to house nodes and links
      # so that nodes always appear above links
      linkContainer = workspace.append("svg:g").classed("linkContainer", true)
      nodeContainer = workspace.append("svg:g").classed("nodeContainer", true)

      # add a trigger for rightclicks of the @el
      $(@el).bind "contextmenu", (e) -> return false #disable defaultcontextmenu
      $(@el).mousedown (e) => 
        if e.which is 3 then @trigger "view:rightclick"
      $(@el).on "dblclick", (e) => 
        @trigger "view:click"

      #Center node on shift+click
      #@addCentering()

      return this

    update: =>

      #@loadtime = 15000 #loadtime before nodes become fixed in ms
      getLinkColor = (link) =>
        if link.color? then link.color else "grey"
      #colors = ["aqua", "black", "blue", "darkblue", "fuchsia", "darkgray", "green", "darkgreen", "lime", "maroon", "navy", "olive", "orange", "purple", "red", "silver", "teal", "yellow"]
      nodes = @model.get("nodes")
      links = @model.get("links")
      filteredLinks = if @linkFilter then @linkFilter.filter(links) else links
      @force.nodes(nodes).links(filteredLinks).start()
      link = @linkSelection = d3.select(@el).select(".linkContainer").selectAll(".link").data(filteredLinks, @model.get("linkHash"))
      linkEnter = link.enter().append("line")
        .attr("class", "link")
        .attr("stroke", (d) => getLinkColor(d))
        .attr 'marker-end', (link) ->
          'url(#Triangle)' #if link.direction is 'forward' or link.direction is 'bidirectional'
        .attr 'marker-start', (link) ->
          'url(#Triangle2)' if link.direction is 'backward' or link.direction is 'bidirectional'

      linkEnter.on("click", (datum, index) =>
        d3.event.stopPropagation()
        if d3.event.shiftKey then shifted = true else shifted = false
        if shifted then @trigger "enter:link:shift:click", datum
        else @trigger "enter:link:click", datum
        )
        .on "dblclick", (datum, index) =>
          @trigger "enter:link:dblclick", datum
        .on "mouseover", (datum, index) =>
          @trigger "enter:link:mouseover", datum
        .on "mouseout", (datum, index) =>
          @trigger "enter:link:mouseout", datum

      #attempt to start a tooltip for links
      # #BROKEN
      # linkEnter.append("rect")
      #     .attr("dx", "10px")
      #     .attr("dy", "10px")
      #     .attr("width", "20px")
      #     .attr("height", "10px")
      #     .attr("stroke", "black")
      #     .attr("fill", "black")
      #     .attr("stroke-width", 2)
      #     .attr('id', (d)=>'link-tooltip'+@model.get("linkHash")(d))
      #     .style("display", "block")
      #     .on "click", (datum,index) =>
      #       @trigger "enter:link:rect:click", datum
      
      
      getSize = (node) =>
        if (node.size>0) then Math.min((node.size),100) else 8

      link.exit().remove()
      link.attr "stroke-width", (link) => 10 * (@linkStrength link)
      node = @nodeSelection = d3.select(@el).select(".nodeContainer").selectAll(".node").data(nodes, @model.get("nodeHash"))
      #disable node dragging
      nodeEnter = node.enter().append("g").attr("class", "node").call(@force.drag)
      #nodeEnter = node.enter().append("g").attr("class", "node")
      nodeEnter.append("text")
           .attr("dx", (d) -> 4+getSize(d))
           .attr("dy", ".35em")
           .text((d) =>
            @findText(d)
          )

      getColor = (node) =>
        if node.color? then node.color else "darkgrey"

      nodeEnter.append("circle")
           .attr("r", (d) => getSize(d))
           .attr("cx", 0)
           .attr("cy", 0)
           .attr("stroke", (d) => getColor(d))
           .attr("fill", "white")
           .attr("stroke-width", 3)

      clickSemaphore = 0
      nodeEnter.on("click", (datum, index) =>
        #ignore drag
        return  if d3.event.defaultPrevented
        d3.event.stopPropagation()
        if d3.event.shiftKey then shifted = true else shifted = false
        datum.fixed = true
        clickSemaphore += 1
        savedClickSemaphore = clickSemaphore
        setTimeout (=>
          if clickSemaphore is savedClickSemaphore
            if shifted then @trigger "enter:node:shift:click", datum
            else @trigger "enter:node:click", datum
            datum.fixed = false
          else
            # increment so second click isn't registered as a click
            clickSemaphore += 1
            datum.fixed = false
        ), 250)
        .on "dblclick", (datum, index) =>
          @trigger "enter:node:dblclick", datum
        .on "mouseover", (datum, index) =>
          @trigger "enter:node:mouseover", datum
        .on "mouseout", (datum, index) =>
          @trigger "enter:node:mouseout", datum
        .on "contextmenu", (datum, index) => 
          @trigger "enter:node:rightclick", datum

      @trigger "enter:node", nodeEnter
      @trigger "enter:link", linkEnter
      node.exit().remove()
      
      @force.start()
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

      @nodeEnter = nodeEnter
      #This code can be used to pin the graph after a certain amount of time
      # setTimeout (()=> 
      #   nodeEnter.each (d)->d.fixed = true
      #   ), @loadtime

    addCentering: () ->
      width = $(@el).width()
      height = $(@el).height() 

      translateParams=[0,0]
           
      @on "enter:node:shift:click", (node) ->
        x = node.x
        y = node.y
        scale = @zoom.scale()
        translateParams = [(width/2 -x)/scale,(height/2-y)/scale]
        #translateParams = [x,y]
        #update translate values
        @zoom.translate([translateParams[0], translateParams[1]])
        @workspace.transition().ease("linear").attr "transform", "translate(#{translateParams}) scale(#{scale})"

    #fast-forward force graph rendering to prevent bouncing http://stackoverflow.com/questions/13463053/calm-down-initial-tick-of-a-force-layout  
    # forwardAlpha: (layout, alpha, max) ->
    #   alpha = alpha || 0
    #   max = max || 1000
    #   i = 0
    #   while layout.alpha() > alpha && i++ < max
    #     layout.tick()

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

    getNodeSelection: ->
      return @nodeSelection

    getLinkSelection: ->
      return @linkSelection

    getForceLayout: ->
      return @force

    getLinkFilter: ->
      return @linkFilter

    #TODO MAKE THIS GENERIC
    findText: (node) ->
      if node.name?
        if (node.name.length>20)
          node.name.substring(0,18)+ "..."
        else
          node.name
      else if node.title?
        if (node.title.length>20)
          node.title.substring(0,18)+ "..."
        else
          node.title
      else
        ''




