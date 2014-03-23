# provides details of the selected nodes
define [], () ->

  class AddNode extends Backbone.View

    constructor: (@options) ->
      super()

    buttons: [{
      id: 'participant',
      fields: {name: '', url: '', email: '', type: 'participant', size: 10, color: '#66CCDD'}
    }, { 
      id: 'mentor', fields: {name: '', url: '', email: '', type: 'mentor', size: 10, color: '#FFBB22'}
    }, {
      id: 'project', fields: {name: '', url: '', description: '', type: 'project', size: 16, color: '#F56545'}
    }, {
      id: 'resource', fields: {name: '', url: '', description: '', type: 'resource', size: 8, color: '#BBE535'}
    }, {
      id: 'theme', fields: {name: '', description: '', type: 'theme', size: 24, color: '#77DDBB'}
    }, {
      id: 'other', fields: {name: '', description: '', size: 10, color: '#A9A9A9'}
    }]

    init: (instances) ->
      @dataController = instances['local/Neo4jDataController']
      @graphModel = instances['GraphModel']
      @selection = instances['NodeSelection']
      @graphView = instances['GraphView']
      @nodeEdit = instances['local/NodeEdit']

      capitalize = (str) -> str[0].toUpperCase() + str.slice 1

      lazy_button_template = (name) -> "<span id=\"add-#{ name }-button\">#{ capitalize name }</span>"

      $omniBox = $('#omniBox')

      $addNode = $("<div id=\"add-node\" class=\"result-element\">\
                      <span>Add Something</span>\
                      <br/>#{ (lazy_button_template b.id for b in @buttons).join '' }</div>").appendTo $omniBox

      $addProfileHelper = $('<div class="node-profile-helper"></div>').appendTo $omniBox

      for button in @buttons
        @initButton button.id, button.fields

    initButton: (name, fields) ->
      $("#add-#{ name }-button").click () =>
        options = {}
        if fields?
          for k, v of fields
            options[k] = v
        @createNode options

    createNode: (node) ->
      @dataController.nodeAdd node, (datum) =>
        datum.fixed = true
        datum.px = ($(window).width()/2-@graphView.currentTranslation[0])/@graphView.currentScale
        datum.py = ($(window).height()/2-@graphView.currentTranslation[1])/@graphView.currentScale
        @graphModel.putNode(datum)
        @selection.toggleSelection(datum)
        @nodeEdit.editNode(datum,$($('.node-profile').slice(-1)[0]),@nodeEdit.blacklist)


