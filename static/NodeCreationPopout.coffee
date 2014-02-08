# provides details of the selected nodes
define [], () ->

  class NodeCreationPopout extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @topBarCreate = instances["local/TopBarCreate"]
      @listenTo instances["local/TopBarCreate"], "popout:open", () => 
        @popout()

      @$el.appendTo $('#maingraph')
      @$blur = $('<div id="blur">').appendTo($('#maingraph')).hide()
      @createPopout()
      @$el.toggle()

    createPopout: ->
      @$el.attr 'id', 'create-node-popout'

      @$formWrapper = $('<div class="form">').
        appendTo @$el

      # sets up html elements for form
      $nodeTitle = $('<h2>Create a Node!</h2>').appendTo @$formWrapper
      $nodeInputName = $('<input id="popout-node-input-name" placeholder=\"Node Name [optional]\" type="name" class="form-control" /><br />').appendTo @$formWrapper
      $nodeInputUrl = $('<input placeholder="Url [optional]" class="form-control"><br>').appendTo @$formWrapper
      $nodeInputDesc = $('<textarea placeholder="Description #key1 value1 #key2 value2" rows="20" class="form-control"></textarea><br>').appendTo @$formWrapper
      $nodeCreateButton = $('<input type="submit" value="Create Node" />').appendTo @$formWrapper

      $nodeCreateButton.click () =>
        contentString = $nodeInputName.val() + " : " + $nodeInputDesc.val() + " #url " + $nodeInputUrl.val()
        @createnode contentString
        @popdown()

      @$blur.click () =>
        @popdown()
      
    popout: ->
      @$el.fadeIn()
      @$blur.fadeIn()
      $('#popout-node-input-name').focus()

    popdown: ->
      @$el.fadeOut()
      @$blur.fadeOut()

    createnode: (content) ->
      @topBarCreate.buildNode(@topBarCreate.parseSyntax(content))


