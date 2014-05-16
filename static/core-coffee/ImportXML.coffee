# provides details of the selected nodes
define [], () ->

  class ImportXML extends Backbone.View

    constructor: (@options) ->
      @parent = ""
      @parent ?= @options.parent
      super()

    init: (instances) ->
      #require plugins
      @dataController = instances['local/Neo4jDataController']

      @graphModel = instances['GraphModel']
      @graphView = instances['GraphView']
      
      @parent = $("#add-node")

      @render()

      @$el.appendTo @parent

    render: ->
      $container = $("<div id=\"xml-update-box\" data-intro='Update database from XML' data-position='left'></div>")
      $container.appendTo @$el

      $container.append("<textarea rows=\"4\" id=\"xmlbox\"></textarea>")

      $updateButton = $("<input type=\"button\" value=\"Update from XML\"></input>").appendTo $container
      $updateButton.click () =>
        jsondata = $.xml2json($("#xmlbox").val())
        for node in jsondata['node']
          for property,value of node
            node[property] = value.replace(/[']/g, "&#039;")
          console.log node
          $.post "/update", node, (data) =>
            console.log data
