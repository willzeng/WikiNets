define ["backbone", "d3"], (Backbone, d3) ->
  margin =
    top: 10
    right: 30
    bottom: 30
    left: 30

  width = 200 - margin.left - margin.right
  height = 200 - margin.top - margin.bottom
  LinkHistogramView = Backbone.View.extend(
    initialize: ->
      @model.on "change:links", @update, this

    render: ->
      @update()
      return this

    update: ->
      @$el.empty()
      @$el.append $("<div class='histogram-header'>Link Strength</div>")
      svg = d3.select(@el)
              .append("svg")
              .classed("histogram", true)
              .attr("width", width + margin.left + margin.right)
              .attr("height", height + margin.top + margin.bottom)
              .append("g")
              .classed("workspace", true)
              .attr("transform", "translate(#{margin.left},#{margin.top})")
      values = _.pluck(@model.getLinks(), "strength")

      # A formatter for counts.
      formatCount = d3.format(",.0f")
      min = 0 # d3.min(values) or 0
      max = 1 # d3.max(values) or 1
      max += .001  if min is max
      x = d3.scale.linear()
                  .domain([min, max])
                  .range([0, width])
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
      xAxis = d3.svg.axis()
                    .scale(x)
                    .orient("bottom")
      bar = svg.selectAll(".bar")
               .data(data)
               .enter()
               .append("g")
               .attr("class", "bar")
               .attr("transform", (d) ->
                    "translate(#{x(d.x)},#{y(d.y)})"
                  )

      bar.append("rect")
         .attr("x", 1)
         .attr("width", (d) ->
            x(d.x + d.dx) - x(d.x) - 1
            )
         .attr("height", (d) ->
            height - y(d.y)
            )

      bar.append("text")
         .attr("dy", ".75em")
         .attr("y", 6)
         .attr("x", (d) ->
            (x(d.x + d.dx) - x(d.x) - 1) / 2
            )
         .attr("text-anchor", "middle")
         .text((d) ->
            formatCount d.y
            )

      svg.append("g")
         .attr("class", "x axis")
         .attr("transform", "translate(0,#{height})")
         .call(xAxis)
  )
  LinkHistogramView
