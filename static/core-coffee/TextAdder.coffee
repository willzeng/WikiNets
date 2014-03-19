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
      console.log "tripleList", tripleList

      sourceExists = false
      targetExists = false

      if tripleList.length is 1
        node = {name: tripleList[0]}
        console.log "onenode"
        @dataController.nodeAdd node, (newNode) =>
          @graphModel.putNode(newNode)
          @selection.toggleSelection(newNode)
      else
        sourceNode = {name: tripleList[0]}
        newLink = {"properties":{name: tripleList[1]}}
        targetNode = {name: tripleList[2]}

        workspaceNodes = @graphModel.getNodes()
        node = ""
        for node in workspaceNodes
          if node.name is sourceNode.name
            sourceExists = true
            sourceNode = node
            console.log "sourceExists"
            break
          else
            sourceExists = false

        node = ""
        for node in workspaceNodes
          if node.name is targetNode.name
            targetExists = true
            targetNode = node
            console.log "targetExists"
            break
          else
            targetExists = false

        if sourceExists
          if targetExists
            @makeLink(newLink, sourceNode, targetNode)
          else
            @dataController.nodeAdd targetNode, (tNode) =>
              @graphModel.putNode(tNode)
              @makeLink(newLink, sourceNode, tNode)
        else
          if targetExists
            @dataController.nodeAdd sourceNode, (sNode) =>
              @graphModel.putNode(sNode)
              @makeLink(newLink, sNode, targetNode)
          else
            @dataController.nodeAdd sourceNode, (sNode) =>
              @graphModel.putNode(sNode)
              #@selection.toggleSelection(sNode)
              @dataController.nodeAdd targetNode, (tNode) =>
                @graphModel.putNode(tNode)
                #@selection.toggleSelection(tNode)
                @makeLink(newLink, sNode, tNode)

    makeLink: (newLink, sourceNode, targetNode) =>
      newLink["source"] = sourceNode
      newLink["target"] = targetNode
      console.log "the new link", newLink
      @dataController.linkAdd newLink, (link) =>
        if link.start == sourceNode['_id']
          link.source = sourceNode
          link.target = targetNode
        else
          link.source = targetNode
          link.target = sourceNode
        @graphModel.putLink link


    parseSyntax: (input) ->
      text = input

      console.log "text", text

      pattern = new RegExp(/(\@[a-z][a-z0-9-_]*)/ig)
      tags = []
      tags.push match[1].trim() while match = pattern.exec(text)

      linkData = text.replace(/(\@[a-z][a-z0-9-_]*)/ig, "").trim()

      if tags.length > 1
        [tags[0].slice(1), linkData, tags[1].slice(1)]
      else
        [tags[0].slice(1)]


