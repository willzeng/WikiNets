# provides details of the selected nodes
define [], () ->

  class AddNode extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @dataController = instances['local/Neo4jDataController']
      @graphModel = instances['GraphModel']
      @selection = instances['NodeSelection']
      @graphView = instances['GraphView']
      @nodeEdit = instances['local/NodeEdit']

      $addNode = $("<div id='add-node' class='result-element'><span>Add Something</span><br/><span id='add-person-button'>Person</span><span id='add-project-button'>Project</span><span id='add-theme-button'>Theme</span><span id='add-other-button'>Other</span></div>").appendTo $('#omniBox')
      $addProfileHelper = $("<div class='node-profile-helper'></div>").appendTo $('#omniBox')

      $('#add-person-button').click () =>
        @createNode({"name":"","url":"", "email":"", "type":"person"})

      $('#add-project-button').click () =>
        @createNode({"name":"","url":"", "description":"", "type":"project"})

      $('#add-theme-button').click () =>
        @createNode({"name":"", "description":"", "type":"theme"})

      $('#add-other-button').click () =>
        @createNode({"name":"", "url":"", "description":""})


    createNode: (node) ->
      @dataController.nodeAdd node, (datum) =>
        datum.fixed = true
        datum.px = ($(window).width()/2-@graphView.currentTranslation[0])/@graphView.currentScale
        datum.py = ($(window).height()/2-@graphView.currentTranslation[1])/@graphView.currentScale
        @graphModel.putNode(datum)
        @selection.toggleSelection(datum)
        @nodeEdit.editNode(datum,$($('.node-profile').slice(-1)[0]),@nodeEdit.blacklist)


