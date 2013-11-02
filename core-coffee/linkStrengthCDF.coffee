define ["core/graphModel", "core/graphView", "core/workspace", "core/singleton"], (GraphModel, GraphView, Workspace, Singleton) ->
  margin =
    top: 10
    right: 30
    bottom: 30
    left: 30

  width = 200 - margin.left - margin.right
  height = 200 - margin.top - margin.bottom
  minStrength = 0
  maxStrength = 1

  class LinkStrengthCDFView extends Backbone.View

    className: "link-cdf"

    constructor: (@model, @graphView) ->
      @listenTo model, "change:links", @paint
      super()

    render: ->

      ### one time setup of link strength cdf view ###

      # add title
      @$el.append $("<div class='cdf-header'>Link Strength CDF</div>")

      # create cleanly transformed workspace to generate display
      @svg = d3.select(@el)
              .append("svg")
              .classed("cdf", true)
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .classed("workspace", true)
              .attr("transform", "translate(#{margin.left},#{margin.top})")
      @svg.append("g")
        .classed("cdfs", true)

      # scale mapping link strength to x coordinate in workspace
      @x = d3.scale.linear()
        .domain([minStrength, maxStrength])
        .range([0, width])

      # scale mapping cdf to y coordinate in workspace
      @y = d3.scale.linear()
        .domain([0, 1])
        .range([height, 0])

      # create axis
      xAxis = d3.svg.axis()
        .scale(@x)
        .orient("bottom")
      @svg.append("g")
         .attr("class", "x axis")
         .attr("transform", "translate(0,#{height})")
         .call(xAxis)

      # initialize plot
      @paint()

      ### create draggable threshold line ###

      # create threshold line
      d3.select(@el).select(".workspace")
        .append("line")
        .classed("threshold-line", true)

      # x coordinate of threshold
      thresholdX = @x(@graphView.getLinkFilter().get("threshold"))

      # draw initial line
      d3.select(@el).select(".threshold-line")
        .attr("x1", thresholdX)
        .attr("x2", thresholdX)
        .attr("y1", 0)
        .attr("y2", height)

      # handling dragging
      @$(".threshold-line").on "mousedown", (e) =>
        $line = @$(".threshold-line")
        pageX = e.pageX
        originalX = parseInt $line.attr("x1")
        d3.select(@el).classed("drag", true)
        $(window).one "mouseup", () ->
          $(window).off "mousemove", moveListener
          d3.select(@el).classed("drag", false)
        moveListener = (e) =>
          @paint()
          dx = e.pageX - pageX
          newX = Math.min(Math.max(0, originalX + dx), width)
          @graphView.getLinkFilter().set("threshold", @x.invert(newX))
          $line.attr("x1", newX)
          $line.attr("x2", newX)
        $(window).on "mousemove", moveListener
        e.preventDefault()

      # for chained calls
      return this

    paint: ->

      ### function called everytime link strengths change ###

      # use histogram layout with many bins to get discrete pdf
      layout = d3.layout.histogram()
        .range([minStrength, maxStrength])
        .frequency(false) # tells d3 to use probabilities, not counts
        .bins(100) # determines the granularity of the display

      # raw distribution of link strengths
      values = _.pluck @model.getLinks(), "strength"
      pdf = layout(values)
      cdf = @getCDF(pdf) # array of {x: <strength>, y: <cdf>} objects
      visibleCDF = _.filter cdf, (bin) => @graphView.getLinkFilter().get("threshold") < bin.x

      # set opacity on area, bad I know
      cdf.opacity = 0.25
      visibleCDF.opacity = 1

      # create area generator based on cdf
      area = d3.svg.area()
        .x((d) => @x(d.x))
        .y0(@y(0))
        .y1((d) => @y(d.y))

      data = [cdf]
      data.push visibleCDF unless visibleCDF.length is 0

      path = d3
        .select(@el)
        .select(".cdfs")
        .selectAll(".cdf")
          .data(data)
      path.enter()
        .append("path")
        .classed("cdf", true)
      path.exit().remove()
      path
        .attr("d", area)
        .style("opacity", (d) -> d.opacity)

    getCDF: (pdf) ->
      ### turn pdf into an array of {x: <strength>, y: <cdf>} objects ###
      cdf = 0
      _.map pdf, (bin) -> x: bin.x, y: cdf += bin.y

  class LinkcdfAPI extends Backbone.Model
    constructor: () ->
      graphModel = GraphModel.getInstance()
      graphView = GraphView.getInstance()
      view = new LinkStrengthCDFView(graphModel, graphView).render()
      workspace = Workspace.getInstance()
      workspace.addTopLeft view.el

  _.extend LinkcdfAPI, Singleton
