# uses quick WikiNets syntax to create up a network of nodes and arrows in the database
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

      #some key press should take you to the SyntaxCreate box. Perhaps SPACE?
      #@listenTo @keyListener, "down:17:65", @selectAll

      @render()

      @graphView.on "enter:node:click", @update.bind(this)

      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Syntax Create'

    render: ->
      $container = $("<div class=\"syntax-create-container\">").appendTo @$el

      $createNodeButton = $("<input id=\"createNodeButton\" type=\"submit\" value=\"New Node\">").appendTo $container
      $createArrowButton = $("<input id=\"createArrowButton\" type=\"submit\" value=\"New Arrow\"><br>").appendTo $container

      $sourceInput = $("<textarea id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo $container
      $createSourceNodeButton = $("<input id=\"queryform\" type=\"button\" value=\"Create Node\"><br>").appendTo $container
      $createSourceNodeButton.click(() => @buildNode(@parseSyntax($sourceInput.val())))

      $arrowInput = $("<textarea id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo $container
      $createLinkButton = $("<input id=\"queryform\" type=\"submit\" value=\"Create Link\"><br>").appendTo $container

      $targetInput = $("<textarea id=\"searchAddNodeField\" name=\"textin\" rows=\"4\" cols=\"27\"></textarea><br>").appendTo $container
      $createTargetNodeButton = $("<input id=\"queryform\" type=\"submit\" value=\"Create (Target) Node\"><br>").appendTo $container

    update: (node) ->
      @selectedNode = node

    buildNode: (node) ->
      console.log "ADD THE NODE: ", node
      @dataController.nodeAdd(node, (datum) => @graphModel.putNode(datum))
      #@graphModel.putNode
    
    parseSyntax: (input) ->
      ###Parse the input query into key value pairs###
      strsplit=input.split("#");
      strsplit[0]=strsplit[0].replace(/:/," #description ");### The : is shorthand for #description ###
      text=strsplit.join("#")

      pattern = new RegExp(/#([a-zA-Z0-9]+) ([^#]+)/g)
      dict = {}
      match = {}
      dict[match[1].trim()]=match[2].trim() while match = pattern.exec(text)

      console.log "This is the dictionary", dict

      ###The first entry becomes the name###
      dict["name"]=text.split("#")[0].trim()
      console.log "This is the title", text.split("#")[0].trim()
      console.log dict
      dict