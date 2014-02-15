# makes nodes "selectable"
define [], () ->

  class LinkHover extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      @graphView = instances['GraphView']
      @linkFilter = @graphView.getLinkFilter()
      @graphModel = instances['GraphModel']
      @dataProvider = instances["local/WikiNetsDataProvider"]

      # div = d3.select("#maingraph").append("div")   
      #     .style("position", "absolute")       
      #     .style("text-align", "center")
      #     .style("padding", "2px")
      #     .style("background", "lightsteelblue")
      #     .style("border", "0px")
      #     .style("border-radius", "8px")
      #     .style("font-size", "9px")
      #     .style("opacity", 0)

      # @graphView.on "enter:node:mouseover", (d) =>
      #     div.transition()        
      #         .duration(200)      
      #         .style("opacity", .9)
      #     div.html("Expand"+ "<br/>")  
      #         .style("left", (d3.event.pageX) + "px")     
      #         .style("top", (d3.event.pageY + 8) + "px")

      @graphView.on "enter:node:mouseover", (d) =>
        $('#expand-button'+@graphModel.get("nodeHash")(d)).show()

      @graphView.on "enter:node:mouseout", (d) =>
        $('#expand-button'+@graphModel.get("nodeHash")(d)).hide()

      @graphView.on "enter:node:rect:click", (d) =>
        @expandSelection(d)

    expandSelection: (d) =>
      @dataProvider.getLinkedNodes [d], (nodes) =>
          _.each nodes, (node) =>
            @graphModel.putNode node if @dataProvider.nodeFilter node