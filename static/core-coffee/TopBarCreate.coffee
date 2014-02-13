# uses quick WikiNets syntax to create a new node in the database (sits in the top middle of the page)
define [], () ->

  class TopBarCreate extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      @keyListener = instances['KeyListener']
      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']
      @dataController = instances['local/Neo4jDataController']

      @buildingLink = false
      @sourceSet = false
      @tempLink = {};
      @render()

      $(@el).appendTo $('#buildbar')

      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)

    render: ->

      $container = $('<div id="topbarcreate">').appendTo @$el

      $nodeSide = $('<div id="nodeside">').appendTo $container

      $nodeHolder = $('<textarea placeholder="Add Node" id="nodeHolder" name="textin" rows="1" cols="35"></textarea>').appendTo $nodeSide

      @$nodeWrapper = $('<div class="source-container">').appendTo $nodeSide

      $nodeInputName = $('<textarea placeholder=\"Node Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      $nodeInputUrl = $('<textarea placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      $nodeInputDesc = $('<textarea placeholder="Description #key1 value1 #key2 value2" rows="5" cols="35"></textarea><br>').appendTo @$nodeWrapper

      $createnodeNodeButton = $('<input id="queryform" type="button" value="Create Node">').appendTo @$nodeWrapper

      $createnodeNodeButton.click () => 
        @buildNode(@parseSyntax($nodeInputName.val()+" : "+$nodeInputDesc.val()+" #url "+$nodeInputUrl.val()))
        $nodeInputName.val('')
        $nodeInputUrl.val('')
        $nodeInputDesc.val('')
        $nodeInputName.focus()
 
      # popout button for more detailed node creation
      $openPopoutButton = $('<i class="right fa fa-expand"></i>').appendTo @$nodeWrapper

      $openPopoutButton.click () =>
        @trigger 'popout:open'
        @$nodeWrapper.hide()
        $nodeHolder.show()

      $linkSide = $('<div id="linkside">').appendTo $container

      $linkHolder = $('<textarea placeholder="Add Link" id="nodeHolder" name="textin" rows="1" cols="35"></textarea><br>').appendTo $linkSide

      @$linkWrapper = $('<div id="source-container">').appendTo $linkSide
      #$linkTitleArea = $('<textarea placeholder="Title" id="nodeTitle" name="textin" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper
      # $linkInput = $('<textarea placeholder="Link : A link\'s description #key1 value1 #key2 value2" id="linkInputField" name="textin" rows="5" cols="35"></textarea><br>').appendTo @$linkWrapper
      $linkInputName = $('<textarea placeholder=\"Link Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper
      $linkInputUrl = $('<textarea placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper
      $linkInputDesc = $('<textarea placeholder="Description\n #key1 value1 #key2 value2" rows="5" cols="35"></textarea><br>').appendTo @$linkWrapper

      $createLinkButton = $('<input id="queryform" type="submit" value="Create Link"><br>').appendTo @$linkWrapper

      $linkingInstructions = $('<span id="toplink-instructions">').appendTo $container

      $createLinkButton.click () =>
        @buildLink(
          tlink = @parseSyntax($linkInputName.val()+" : "+$linkInputDesc.val()+" #url "+$linkInputUrl.val())
          # if tlink.name is "" then tlink.name = "link"
          # console.log $linkInputName.val()+" : "+$linkInputDesc.val()+" #url "+$linkInputUrl.val()
        )
        $linkInputName.val('')
        $linkInputUrl.val('')
        $linkInputDesc.val('')
        # $linkInput.blur()
        @$linkWrapper.hide()
        $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">Click two Nodes to link them.</span>')

      @$nodeWrapper.hide()
      @$linkWrapper.hide()

      $nodeHolder.focus () =>
        @$nodeWrapper.show()
        $nodeInputName.focus()
        $nodeHolder.hide()

      $linkHolder.focus () =>
        @$linkWrapper.show()
        $linkInputName.focus()
        $linkHolder.hide()

      @graphView.on "view:click", () => 
        if @$nodeWrapper.is(':visible')
          @$nodeWrapper.hide()
          $nodeHolder.show()
        if @$linkWrapper.is(':visible')
          @$linkWrapper.hide()
          $linkHolder.show()

      @graphView.on "enter:node:click", (node) =>
        if @buildingLink
          if @sourceSet
            @tempLink.target = node
            link = @tempLink
            @dataController.linkAdd(link, (linkres)=> 
              newLink = linkres
              allNodes = @graphModel.getNodes()
              newLink.source = n for n in allNodes when n['_id'] is link.source['_id']
              newLink.target = n for n in allNodes when n['_id'] is link.target['_id']
              @graphModel.putLink(newLink)
              )
            @sourceSet = @buildingLink = false
            $('#toplink-instructions').replaceWith('<span id="toplink-instructions"></span>')
            $linkHolder.show()
          else
            @tempLink.source = node
            @sourceSet = true
            $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">Click two Nodes to link them.</span>')

    update: (node) ->
      @selection.getSelectedNodes()

    buildNode: (node) ->
      @dataController.nodeAdd(node, (datum) => @graphModel.putNode(datum))

    buildLink: (linkProperties) ->
      @tempLink.properties = linkProperties
      console.log "tempLink set to", @tempLink
      @buildingLink = true
    
    parseSyntax: (input) ->
      console.log "input", input
      strsplit=input.split('#');
      strsplit[0]=strsplit[0].replace(/:/," #description ");### The : is shorthand for #description ###
      text=strsplit.join('#')

      pattern = new RegExp(/#([a-zA-Z0-9]+) ([^#]+)/g)
      dict = {}
      match = {}
      dict[match[1].trim()]=match[2].trim() while match = pattern.exec(text)

      ###The first entry becomes the name###
      dict["name"]=text.split('#')[0].trim()
      console.log "This is the title", text.split('#')[0].trim()
      createDate=new Date()
      dict["_Creation_Date"]=createDate
      dict