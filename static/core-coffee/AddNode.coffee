# provides details of the selected nodes
define [], () ->

  class AddNode extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @dataController = instances['local/Neo4jDataController']

      $addNode = $("<div id='add-node' class='result-element'><span>Add Node</span><br/><span id='add-node-button'>Person</span><span>Project</span><span>Theme</span><span>Other</span></div>").appendTo $('#omniBox')
      $addProfileHelper = $("<div class='node-profile-helper'></div>").appendTo $('#omniBox')

      $('.add-node-button').click () =>
        @dataController.nodeAdd()


