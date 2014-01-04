# uses quick WikiNets syntax to create a new node in the database (opens on rightclick as an overlay)
define [], () ->

  class OverlayCreate extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      @keyListener = instances['KeyListener']
      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']
      @dataController = instances['local/Neo4jDataController']

      @render()

      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)

    render: ->

      $container = $("<div id=\"notepad\">").appendTo @$el

      $titleArea = $("<textarea placeholder=\"Title\" id=\"nodeTitle\" name=\"textin\" rows=\"1\" cols=\"59\"></textarea><br>").appendTo $container

      @$sourceWrapper = $("<div class=\"source-container\">").appendTo $container
      $sourceInput = $("<textarea placeholder=\"Node : A node's description #key1 value1 #key2 value2\" id=\"nodeContent\" name=\"textin\" rows=\"14\" cols=\"59\"></textarea><br>").appendTo @$sourceWrapper

      $createSourceNodeButton = $("<input id=\"queryform\" type=\"button\" value=\"Create Node\"><br>").appendTo @$sourceWrapper
      
      $("#nodeContent").keypress (e) =>
        console.log e.keyCode
        if e.keyCode is 13
          @buildNode(@parseSyntax($sourceInput.val()))
          $sourceInput.val("")

      $createSourceNodeButton.click () => 
        @buildNode(@parseSyntax($sourceInput.val()))
        $sourceInput.val("")
        $('#overlay').hide()
        @$el.hide()

      @setupOverlay()

    setupOverlay: () =>
      $overlay = $("<div id=\"overlay\">").appendTo @graphView.$el.parent()
      @$el.appendTo $('#overlay').parent()
      $('#overlay').hide()
      @$el.hide()

      $overlay.click () =>
        $('#overlay').hide()
        @$el.hide()

      @$el.bind "contextmenu", (e) -> return false #disable defaultcontextmenu
      $overlay.bind "contextmenu", (e) -> return false #disable defaultcontextmenu

      @graphView.on "view:rightclick", () => 
        $('#overlay').show()
        #@$el.appendTo $('#overlay').parent()
        @$el.show()

    update: (node) ->
      @selection.getSelectedNodes()

    buildNode: (node) ->
      @dataController.nodeAdd(node, (datum) => @graphModel.putNode(datum))
    
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