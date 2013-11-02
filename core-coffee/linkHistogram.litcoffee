## API

## Code

    define ["core/graphModel", "core/graphView", "core/workspace", "core/singleton"], (GraphModel, GraphView, Workspace, Singleton) ->
      margin =
        top: 10
        right: 30
        bottom: 30
        left: 30

      width = 200 - margin.left - margin.right
      height = 200 - margin.top - margin.bottom
      min = 0
      max = 1

      class LinkHistogramView extends Backbone.View

        constructor: (@model, @graphView) ->
          @listenTo model, "change:links", @paint
          super()

        render: ->
          @$el.append $("<div class='histogram-header'>Link Strength</div>")
          @svg = d3.select(@el)
                  .append("svg")
                  .classed("histogram", true)
                  .attr("width", width + margin.left + margin.right)
                  .attr("height", height + margin.top + margin.bottom)
                  .append("g")
                  .classed("workspace", true)
                  .attr("transform", "translate(#{margin.left},#{margin.top})")
          x = @x = d3.scale.linear()
                      .domain([min, max])
                      .range([0, width])
          xAxis = d3.svg.axis()
                        .scale(x)
                        .orient("bottom")
          @svg.append("g")
             .attr("class", "x axis")
             .attr("transform", "translate(0,#{height})")
             .call(xAxis)
          @paint()
          d3.select(@el).select(".workspace")
            .append("line")
            .classed("threshold-line", true)
          thresholdX = @x(@graphView.getLinkFilter().get("threshold"))
          d3.select(@el).select(".threshold-line")
            .attr("x1", thresholdX)
            .attr("x2", thresholdX)
            .attr("y1", 0)
            .attr("y2", height)
          @$(".threshold-line").on "mousedown", (e) =>
            $line = @$(".threshold-line")
            pageX = e.pageX
            originalX = parseInt $line.attr("x1")
            d3.select($line.get()[0]).classed("drag", true)
            $(window).one "mouseup", () ->
              $(window).off "mousemove", moveListener
              d3.select($line.get()[0]).classed("drag", false)
            moveListener = (e) =>
              @paint()
              dx = e.pageX - pageX
              newX = Math.min(Math.max(0, originalX + dx), width)
              @graphView.getLinkFilter().set("threshold", x.invert(newX))
              $line.attr("x1", newX)
              $line.attr("x2", newX)
            $(window).on "mousemove", moveListener
          return this

        paint: ->

          values = _.pluck @model.getLinks(), "strength"

          numBins = 5
          ticks = []
          i = 0
          while i < numBins + 1
            ticks.push min + (max - min) * i / (numBins)
            ++i

          data = d3.layout.histogram().bins(ticks)(values)

          y = d3.scale.linear().domain([0, d3.max(data, (d) ->
            d.y
          )]).range([height, 0])

          bar = @svg.selectAll(".bar").data(data)
          bar.enter()
             .append("g")
             .attr("class", "bar")
             .append("rect")

          # A formatter for counts.
          formatCount = d3.format(",.0f")
          bar
            .attr("transform", (d) => "translate(#{@x(d.x)},#{y(d.y)})")
            .select("rect")
            .attr("width", (d) => @x(d.x + d.dx) - @x(d.x))
            .attr("height", (d) => height - y(d.y))
            .style("opacity", (d) =>
              threshold = @graphView.getLinkFilter().get("threshold")
              return 0.25 + 0.75 * (1 - Math.min(1, Math.max(0, (threshold - d.x) / d.dx)))
            )

      class LinkHistogramAPI extends Backbone.Model
        constructor: () ->
          graphModel = GraphModel.getInstance()
          graphView = GraphView.getInstance()
          view = new LinkHistogramView(graphModel, graphView).render()
          workspace = Workspace.getInstance()
          workspace.addTopLeft view.el

      _.extend LinkHistogramAPI, Singleton
