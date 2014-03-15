# provides details of the selected nodes
define [], () ->

  class LinkCreationPopout extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @topBarCreate = instances["local/TopBarCreate"]
      @listenTo instances["local/TopBarCreate"], "link_create:popout:open", () =>
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
      $linkTitle = $('<h1 class="modal-title">Create a Link!</h1>').appendTo @$formWrapper
      $linkInputName = $('<input id="popout-link-input-name" placeholder=\"Link Name [optional]\" type="text" class="form-control" /><br />').appendTo @$formWrapper
      $linkInputUrl = $('<input type="text" placeholder="Url [optional]" class="form-control"><br>').appendTo @$formWrapper
      $linkInputDesc = $('<textarea placeholder="Description #key1 value1 #key2 value2" rows="20" class="form-control"></textarea><br>').appendTo @$formWrapper
      $linkCreateButton = $('<input type="submit" value="Create Link">').appendTo @$formWrapper

      $linkCreateButton.click () =>
        @createLink()
        @popdown()

      @$blur.click () =>
        @popdown()
      
    popout: ->
      @$el.fadeIn()
      $('#popout-node-input-name').focus()

    popdown: ->
      @$el.fadeOut()

    createLink: (content) ->
      @topBarCreate.createLink()