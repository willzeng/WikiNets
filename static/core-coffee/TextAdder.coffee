# provides details of the selected nodes
define [], () ->

  class TextAdder extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @dataController = instances['local/Neo4jDataController']
      @graphModel = instances['GraphModel']
      @selection = instances['NodeSelection']
      @linkSelection = instances['LinkSelection']
      @graphView = instances['GraphView']
      @nodeEdit = instances['local/NodeEdit']
      @expander = instances['Expander']

      $addNode = $("<div id='add-node-text' class='result-element'><span>Create in the Rhizi</span><br/><br/></div>").appendTo $('#omniBox')
      $addProfileHelper = $("<div class='node-profile-helper'></div>").appendTo $('#omniBox')

      $inputArea = $("<textarea id='textAdder-input' placeholder='@rhizi makes @graphs' rows='5' cols='32'></textarea>").appendTo $addNode
      $inputButton = $("<input type='button' value='Create'></input>").appendTo $addNode

      $inputButton.click () =>
        @createTriple @parseSyntax($inputArea.val())
        $inputArea.val("")
        $inputArea.focus()

      $inputArea.keyup (e) =>
        if(e.keyCode == 13) # enter key
          @createTriple @parseSyntax($inputArea.val())
          $inputArea.val("")
          $inputArea.focus()

    createTriple: (tripleList) =>
      console.log tripleList
      if tripleList.length is 1
        node = {name: tripleList[0]}
        @dataController.nodeAdd node, (newNode) =>
          @graphModel.putNode(newNode)
          @selection.toggleSelection(newNode)
      else
        sourceNode = {name: tripleList[0]}
        newLink = {"properties":{name: tripleList[1]}}
        targetNode = {name: tripleList[2]}
        @dataController.nodeAdd sourceNode, (sNode) =>
          @graphModel.putNode(sNode)
          @selection.toggleSelection(sNode)
          @dataController.nodeAdd targetNode, (tNode) =>
            @graphModel.putNode(tNode)
            @selection.toggleSelection(tNode)
            newLink["source"] = sNode
            newLink["target"] = tNode
            @dataController.linkAdd newLink, (link) =>
              if link.start == sNode['_id']
                link.source = sNode
                link.target = tNode
              else
                link.source = tNode
                link.target = sNode
              @graphModel.putLink link
              @linkSelection.toggleSelection(link)

    parseSyntax: (input) ->
      text = input

      pattern = new RegExp(/(\@[a-z][a-z0-9-_]*)/ig)
      tags = []
      tags.push match[1].trim() while match = pattern.exec(text)

      linkData = text.replace(/(\@[a-z][a-z0-9-_]*)/ig, "").trim()

      console.log "tags", tags

      if tags.length > 1
        [tags[0].slice(1), linkData, tags[1].slice(1)]
      else
        [tags[0].slice(1)]


