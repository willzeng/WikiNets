# provides a variably smoothed PDF of the distribution link strengths.
# also provides a slider on that distribution
# which filters out links with weight below that threshold.
define [], () ->

  margin =
    top: 10
    right: 10
    bottom: 40
    left: 10

  width = 200 - margin.left - margin.right
  height = 200 - margin.top - margin.bottom
  minStrength = 0
  maxStrength = 1

  class LinkDistributionView extends Backbone.View

    className: "link-pdf"

    constructor: (@options) ->
      @windowModel = new Backbone.Model()
      @windowModel.set("window", 10)
      @listenTo @windowModel, "change:window", @paint
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @graphView = instances["GraphView"]
      @listenTo instances["GraphModel"], "change:links", @paint
      scale = d3.scale.linear()
        .domain([2,200])
        .range([0, 100])
      instances["Sliders"].addSlider "Smoothing", scale(@windowModel.get("window")), (val) =>
        @windowModel.set "window", scale.invert(val)
      @render()
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Link Distribution'

    render: ->

      ### one time setup of link strength pdf view ###

      # create cleanly transformed workspace to generate display
      @svg = d3.select(@el)
              .append("svg")
              .classed("pdf", true)
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .classed("workspace", true)
              .attr("transform", "translate(#{margin.left},#{margin.top})")
      @svg.append("g")
        .classed("pdfs", true)

      # scale mapping link strength to x coordinate in workspace
      @x = d3.scale.linear()
        .domain([minStrength, maxStrength])
        .range([0, width])

      # create axis
      xAxis = d3.svg.axis()
        .scale(@x)
        .orient("bottom")
      bottom = @svg.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0,#{height})")
      bottom.append("g")
        .call(xAxis)
      bottom.append("text")
        .classed("label", true)
        .attr("x", width / 2)
        .attr("y", 35)
        .text("Link Strength")

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
        $(window).one "mouseup", () =>
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
      values = _.pluck @graphModel.getLinks(), "strength"
      sum = 0
      cdf = _.chain(layout(values))
        .map (bin) ->
          "x": bin.x, "y": sum += bin.y
        .value()
      halfWindow = Math.max 1, parseInt(@windowModel.get("window")/2)
      pdf = _.map cdf, (bin, i) ->
        # get quantiles
        q1 = Math.max 0, i - halfWindow
        q2 = Math.min cdf.length - 1, i + halfWindow
        # get y value at quantiles
        y1 = cdf[q1]["y"]
        y2 = cdf[q2]["y"]
        # get slope
        slope = (y2 - y1) / (q2 - q1)
        # return slope as y to produce a smoothed derivative
        return "x": bin.x, "y": slope

      # scale mapping cdf to y coordinate in workspace
      maxY = _.chain(pdf)
        .map((bin) -> bin.y)
        .max()
        .value()
      @y = d3.scale.linear()
        .domain([0, maxY])
        .range([height, 0])

      # create area generator based on pdf
      area = d3.svg.area()
        .interpolate("monotone")
        .x((d) => @x(d.x))
        .y0(@y(0))
        .y1((d) => @y(d.y))

      ###

      define the x and y points to use for the visible links.
      they should be the points from the original pdf that are above
      the threshold

      to avoid granularity issues (jdhenke/celestrium#75),
      we also prepend this list of points with a point with x value exactly at
      the threshold and y value that is the average of it's neighbors' y values

      ###

      threshold = @graphView.getLinkFilter().get("threshold")
      visiblePDF = _.filter pdf, (bin) =>
        bin.x > threshold
      if visiblePDF.length > 0
        i = pdf.length - visiblePDF.length
        if i > 0
          y = (pdf[i-1].y + pdf[i].y) / 2.0
        else
          y = pdf[i].y
        visiblePDF.unshift
          "x": threshold
          "y": y

      # set opacity on area, bad I know
      pdf.opacity = 0.25
      visiblePDF.opacity = 1

      data = [pdf]
      data.push visiblePDF unless visiblePDF.length is 0

      path = d3
        .select(@el)
        .select(".pdfs")
        .selectAll(".pdf")
          .data(data)
      path.enter()
        .append("path")
        .classed("pdf", true)
      path.exit().remove()
      path
        .attr("d", area)
        .style("opacity", (d) -> d.opacity)
