# uses quick WikiNets syntax to create a new node in the database (sits in the top middle of the page)
define [], () ->

  class TopBarCreate extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      _.extend this, Backbone.Events

      # different connections
      @keyListener = instances['KeyListener']
      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']
      @dataController = instances['local/Neo4jDataController']
      @selection = instances["NodeSelection"]
      @linkSelection = instances["LinkSelection"]

      ## HELP
      @buildingLink = false
      @tempLink = {};
      @sourceSet = false

      @render()

    render: ->
      # initial creation of html
      container = $('<div id="topbarcreate">').appendTo $('#buildbar')

      # node creation fields

      # html fields
      nodeSide = $('<div id="nodeside">').appendTo container
      nodeHolder = $('<textarea placeholder="Add Node" id="nodeHolder" name="textin" rows="1" cols="35">').appendTo nodeSide
      nodeWrapper = $('<div class="small-form">').appendTo(nodeSide).hide()

      # name, url, descriptions
      nodeInputName = $('<input type="text" placeholder=\"Node Name [optional]\">').appendTo nodeWrapper
      nodeInputUrl = $('<input type="text" placeholder="Url [optional]">').appendTo nodeWrapper
      nodeInputDesc = $('<textarea placeholder="Description [optional]" rows="1" cols="35"></textarea>').appendTo nodeWrapper

      nodeHolder.focus () ->
        nodeWrapper.show()
        nodeInputName.focus()
        nodeHolder.hide()

      # create button and action
      createNodeButton = $('<input type="button" value="Create Node">')
                            .appendTo(nodeWrapper)
                            .click =>
                              @createNode nodeInputName.val(), nodeInputUrl.val(), nodeInputDesc.val(), =>
                                      nodeInputName.val('')
                                      nodeInputDesc.val('')
                                      nodeInputUrl.val('')

      # popout button for more detailed node creation
      openPopoutButton = $('<i class="right fa fa-expand"></i>').appendTo nodeWrapper
      openPopoutButton.click () =>
        @trigger 'popout:open'
        nodeWrapper.hide()
        nodeHolder.show()

      # linkside
      linkSide = $('<div id="linkside">').appendTo(container)

      linkHolder = $('<input type="text" placeholder="Add Link" id="linkHolder">').appendTo linkSide


      linkWrapper = $('<div class="small-form">')
                      .appendTo(linkSide)
                      .hide()

      @linkInputName = $('<input type="text" placeholder="Link Name [optional]">').appendTo linkWrapper
      @linkInputUrl = $('<input type="text"  placeholder="Url [optional]" >').appendTo linkWrapper
      @linkInputDesc = $('<textarea placeholder="Description [optional]" rows="1" cols="35">').appendTo linkWrapper

      @createLinkButton = $('<input id="LinkCreateButton" type="button" value="Attach & Create Link">').appendTo linkWrapper

      linkingInstructions = $('<span id="toplink-instructions">').appendTo container

      # what we do when we create a link
      @createLinkButton.click () =>
        if @buildingLink
          # this is when we are cancelling creating a link
          @buildingLink = false
          @tempLink = {};
          @sourceSet = false
          $('#toplink-instructions').text('')
          @createLinkButton.val('Attach & Create Link')
          @linkInputName.focus()
        else
          # start creating a link
          @buildLink()

      linkHolder.focus () =>
        linkWrapper.show()
        @linkInputName.focus()
        linkHolder.hide()

      @graphView.on "view:click", () =>
        nodeWrapper.hide()
        nodeHolder.show()
        linkWrapper.hide()
        linkHolder.show()

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
              @linkSelection.toggleSelection(newLink)
              )
            @sourceSet = @buildingLink = false
            $('.LinkCreateDiv').each( (i, obj) ->
              $(this)[0].parentNode.removeChild $(this)[0]
            )
            @linkInputName.val('')
            @linkInputDesc.val('')
            @linkInputUrl.val('')
            $('#toplink-instructions').text('')
            @createLinkButton.val('Attach & Create Link')
            @linkInputName.focus()
          else
            @tempLink.source = node
            @sourceSet = true
            $('#toplink-instructions').text('Source:' + node.name + ' (' + node['_id'] + ') Click a node to select it as the link target.')

    sanitize: (propertyVal) =>
      propertyVal.replace(/'/g, "\\'")

    createNode: (name = '', url = '', description = '', onSuccess) =>
      properties = {'name': name, 'url': url, 'description': description, '_Creation_Date': new Date()}
      properties[i] = sanitize(val) for val, i in properties

      if !name
        alert "Your node does not have a name! Please assign your node a name."
      else
        @dataController.nodeAdd properties, (datum) =>
          datum.fixed = true
          datum.px = ($(window).width()/2-@graphView.currentTranslation[0])/@graphView.currentScale
          datum.py = ($(window).height()/2-@graphView.currentTranslation[1])/@graphView.currentScale
          @graphModel.putNode(datum)
          @selection.toggleSelection(datum)
        onSuccess()

    buildLink: (name = '', url = '', description = '', on_success) =>
      properties = {'name': name, 'url': url, 'description': description, '_Creation_Date': new Date()}
      properties[i] = sanitize(val) for val, i in properties

      @tempLink["properties"] = properties
      @buildingLink = true
      $('#toplink-instructions').text('Click a node to select it as the link source.')
      @createLinkButton.val('Cancel Link Creation')
