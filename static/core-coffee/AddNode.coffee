# provides details of the selected nodes
define [], () ->

  class AddNode extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @selection = instances["NodeSelection"]
      #@selection.on "change", @update.bind(this)

    update: ->
      $addNode = $("<div id='add-node' class='result-element'><span>Add Node</span><br/><span>Person</span><span>Project</span><span>Theme</span><span>Other</span></div>").appendTo $('#omniBox')
