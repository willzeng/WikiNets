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
      @$blur = $('<div id="blur"><div>').appendTo @$el
      @createPopout()
      @$el.hide()

    createPopout: ->
      @$el.attr 'class', 'modal-container'
      @$modal = $('<div></div>').appendTo @$el
      @$modal.attr {
        id: 'create-node-popout',
        class: 'modal'
      }

      @$formWrapper = $('<div class="form">').
        appendTo @$modal

      # sets up html elements for form
      $nodeTitle = $('<h1 class="modal-title">Create a Node!</h1>').appendTo @$formWrapper
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
      $('#popout-node-input-name').focus()

    popdown: ->
      @$el.fadeOut()

    createnode: (content) ->
      @topBarCreate.buildNode(@topBarCreate.parseSyntax(content))


