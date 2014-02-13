# uses quick WikiNets syntax to create up a network of nodes and links in the database
define [], () ->

  class SyntaxCreate extends Backbone.View

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

      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Syntax Create'

    render: ->

      $overlay = $("<div class=\"overlay\">")

      $container = $("<div class=\"syntax-create-container\">").appendTo @$el

      $createNodeButton = $("<input id=\"createNodeButton\" type=\"submit\" value=\"New Node\">").appendTo $container
      $createLinkButton = $("<input id=\"createArrowButton\" type=\"submit\" value=\"New Link\"><br>").appendTo $container

      @$sourceWrapper = $("<div class=\"source-container\">").appendTo $container
      $sourceInput = $("<textarea placeholder=\"Node : A node's description #key1 value1 #key2 value2\" id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo @$sourceWrapper

      $createSourceNodeButton = $("<input id=\"queryform\" type=\"button\" value=\"Create Node\"><br>").appendTo @$sourceWrapper

      @$linkWrapper = $("<div id=\"source-container\">").appendTo $container
      $linkInput = $("<textarea placeholder=\"Link : A link's description #key1 value1 #key2 value2\" id=\"linkInputField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo @$linkWrapper

      $createLinkButton = $("<input id=\"queryform\" type=\"submit\" value=\"Create Link\"><br>").appendTo @$linkWrapper

      $linkingInstructions = $("<span id=\"link-instructions\">").appendTo @$linkWrapper

      $createNodeButton.click(() => $sourceInput.focus())
      $createLinkButton.click(() => $linkInput.focus())
      
      $("#searchAddNodeField").keypress (e) =>
        console.log e.keyCode
        if e.keyCode is 13
          @buildNode(@parseSyntax($sourceInput.val()))
          $sourceInput.val("")

      $createSourceNodeButton.click () => 
        @buildNode(@parseSyntax($sourceInput.val()))
        $sourceInput.val("")

      $createLinkButton.click () =>
        @buildLink(@parseSyntax($linkInput.val()))
        $linkInput.val("")
        $("#link-instructions").replaceWith("<span id=\"link-instructions\" style=\"font-style:italic;\">Click to select source</span>")

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
            $("#link-instructions").replaceWith("<span id=\"link-instructions\" style=\"font-style:italic;\"></span>")
          else
            @tempLink.source = node
            @sourceSet = true
            $("#link-instructions").replaceWith("<span id=\"link-instructions\" style=\"font-style:italic;\">Click to select target</span>")

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
      dict