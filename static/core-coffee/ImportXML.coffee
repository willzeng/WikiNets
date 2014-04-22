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
      $updateButton = $("<div><input type=\"button\" class=\"theme-button\" value=\"Update from XML\"></input></div>").appendTo @$el
      $updateButton.click () =>
          alert("Will be installed on Tuesday...")
