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

      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)

    render: ->

      $container = $("<div id=\"topbarcreate\">").appendTo @$el

      $nodeSide = $("<div id=\"nodeside\" style=\"float:left;\">").appendTo $container

      $nodeHolder = $("<textarea placeholder=\"Add Node\" id=\"nodeHolder\" name=\"textin\" rows=\"1\" cols=\"35\"></textarea>").appendTo $nodeSide

      @$sourceWrapper = $("<div class=\"source-container\">").appendTo $nodeSide
      #$nodeTitleArea = $("<textarea placeholder=\"Title\" id=\"nodeTitle\" name=\"textin\" rows=\"1\" cols=\"35\"></textarea><br>").appendTo @$sourceWrapper
      $sourceInput = $("<textarea placeholder=\"Node : A node's description #key1 value1 #key2 value2\" id=\"nodeContent\" name=\"textin\" rows=\"10\" cols=\"35\"></textarea><br>").appendTo @$sourceWrapper

      $createSourceNodeButton = $("<input id=\"queryform\" type=\"button\" value=\"Create Node\">").appendTo @$sourceWrapper

      $createSourceNodeButton.click () => 
        @buildNode(@parseSyntax($sourceInput.val()))
        $sourceInput.val("")

      $linkSide = $("<div id=\"linkside\" style=\"float:right;\">").appendTo $container

      $linkHolder = $("<textarea placeholder=\"Add Link\" id=\"nodeHolder\" name=\"textin\" rows=\"1\" cols=\"35\"></textarea><br>").appendTo $linkSide

      @$linkWrapper = $("<div id=\"source-container\">").appendTo $linkSide
      #$linkTitleArea = $("<textarea placeholder=\"Title\" id=\"nodeTitle\" name=\"textin\" rows=\"1\" cols=\"35\"></textarea><br>").appendTo @$linkWrapper
      $linkInput = $("<textarea placeholder=\"Link : A link's description #key1 value1 #key2 value2\" id=\"linkInputField\" name=\"textin\" rows=\"10\" cols=\"35\"></textarea><br>").appendTo @$linkWrapper

      $createLinkButton = $("<input id=\"queryform\" type=\"submit\" value=\"Create Link\"><br>").appendTo @$linkWrapper

      $linkingInstructions = $("<span id=\"toplink-instructions\">").appendTo $container

      $createLinkButton.click () =>
        @buildLink(@parseSyntax($linkInput.val()))
        $linkInput.val("")
        @$linkWrapper.hide()
        $("#toplink-instructions").replaceWith("<span id=\"toplink-instructions\">Click a Node to select source</span>")

      @$sourceWrapper.hide()
      @$linkWrapper.hide()

      $nodeHolder.focus () =>
        @$sourceWrapper.show()
        $nodeHolder.hide()

      $linkHolder.focus () =>
        @$linkWrapper.show()
        $linkHolder.hide()

      @graphView.on "view:click", () => 
        if @$sourceWrapper.is(':visible')
          @$sourceWrapper.hide()
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
            $("#toplink-instructions").replaceWith("<span id=\"toplink-instructions\"></span>")
            $linkHolder.show()
          else
            @tempLink.source = node
            @sourceSet = true
            $("#toplink-instructions").replaceWith("<span id=\"toplink-instructions\">Click a Node to select target</span>")

      @$el.appendTo @graphView.$el.parent()

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
      strsplit=input.split("#");
      strsplit[0]=strsplit[0].replace(/:/," #description ");### The : is shorthand for #description ###
      text=strsplit.join("#")

      pattern = new RegExp(/#([a-zA-Z0-9]+) ([^#]+)/g)
      dict = {}
      match = {}
      dict[match[1].trim()]=match[2].trim() while match = pattern.exec(text)

      ###The first entry becomes the name###
      dict["name"]=text.split("#")[0].trim()
      console.log "This is the title", text.split("#")[0].trim()
      if dict.name is "" then dict.name = "link"
      dict