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
      @tempLink = {};
      @sourceSet = false
      @render()

      @selection = instances["NodeSelection"]
      @linkSelection = instances["LinkSelection"]

    render: ->

      $container = $('<div id="topbarcreate">').appendTo $('#buildbar')

      $nodeSide = $('<div id="nodeside">').appendTo $container

      $nodeHolder = $('<textarea placeholder="Add Node" id="nodeHolder" name="textin" rows="1" cols="35"></textarea>').appendTo $nodeSide

      @$nodeWrapper = $('<div id="NodeCreateContainer">').appendTo $nodeSide

      @$nodeInputName = $('<textarea id="NodeCreateName" placeholder=\"Node Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      @$nodeInputUrl = $('<textarea id="NodeCreateUrl" placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      @$nodeInputDesc = $('<textarea id="NodeCreateDesc" placeholder="Description [optional]" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      #@$nodeInputColor = $('<textarea id="NodeCreateColor" placeholder="Color [optional]" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      #@$nodeInputSize = $('<textarea id="NodeCreateSize" placeholder="Size [optional]" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper

      $nodeInputForm = $('<form id="NodeCreateForm"></form>').appendTo @$nodeWrapper
      nodeInputNumber = 0

      $nodeMoreFields = $("<input id=\"moreNodeCreateFields\" type=\"button\" value=\"+\">").appendTo @$nodeWrapper
      $nodeMoreFields.click(() => 
        @addField(nodeInputNumber, "NodeCreate")
        nodeInputNumber = nodeInputNumber+1
        )

      $createNodeButton = $('<input id="queryform" type="button" value="Create Node">').appendTo @$nodeWrapper

      $createNodeButton.click(@createNode)

 
      # popout button for more detailed node creation
      $openPopoutButton = $('<i class="right fa fa-expand"></i>').appendTo @$nodeWrapper

      $openPopoutButton.click () =>
        @trigger 'popout:open'
        @$nodeWrapper.hide()
        $nodeHolder.show()


      $linkSide = $('<div id="linkside">').appendTo $container

      $linkHolder = $('<textarea placeholder="Add Link" id="linkHolder" name="textin" rows="1" cols="35"></textarea>').appendTo $linkSide


      @$linkWrapper = $('<div id="LinkCreateContainer">').appendTo $linkSide

      @$linkInputName = $('<textarea id="LinkCreateName" placeholder=\"Link Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper
      @$linkInputUrl = $('<textarea id="LinkCreateUrl" placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper
      @$linkInputDesc = $('<textarea id="LinkCreateDesc" placeholder="Description [optional]" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper

      $linkInputForm = $('<form id="LinkCreateForm"></form>').appendTo @$linkWrapper
      linkInputNumber = 0

      $linkMoreFields = $("<input id=\"moreLinkCreateFields\" type=\"button\" value=\"+\">").appendTo @$linkWrapper
      $linkMoreFields.click(() => 
        @addField(linkInputNumber, "LinkCreate")
        linkInputNumber = linkInputNumber+1
        )

      @$createLinkButton = $('<input id="LinkCreateButton" type="button" value="Attach & Create Link">').appendTo @$linkWrapper

      $linkingInstructions = $('<span id="toplink-instructions">').appendTo $container

      @$createLinkButton.click () =>
        if @buildingLink
          @buildingLink = false
          @tempLink = {};
          @sourceSet = false
          $('#toplink-instructions').replaceWith('<span id="toplink-instructions"></span>')
          @$createLinkButton.val('Attach & Create Link')
          @$linkInputName.focus()
        else
          @buildLink()

      @$nodeWrapper.hide()
      @$linkWrapper.hide()

      $nodeHolder.focus () =>
        @$nodeWrapper.show()
        @$nodeInputName.focus()
        $nodeHolder.hide()

      $linkHolder.focus () =>
        @$linkWrapper.show()
        @$linkInputName.focus()
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
              @linkSelection.toggleSelection(newLink)
              )
            @sourceSet = @buildingLink = false
            $('.LinkCreateDiv').each( (i, obj) ->
              $(this)[0].parentNode.removeChild $(this)[0]
            )
            @$linkInputName.val('')
            @$linkInputDesc.val('')
            @$linkInputUrl.val('')
            $('#toplink-instructions').replaceWith('<span id="toplink-instructions"></span>')
            @$createLinkButton.val('Attach & Create Link')
            @$linkInputName.focus()
          else
            @tempLink.source = node
            @sourceSet = true
            $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">Source:' + @findHeader(node) + ' (' + node['_id'] + ')<br />Click a node to select it as the link target.</span>')

    update: (node) ->
      @selection.getSelectedNodes()

    ###
    Adds a set of property & value input fields to the form /name/, together
    with a button for deleting them
    The inputIndex is a counter that serves as a unique identifier for each
    such set of fields.
    A defaultKey and defaultValue may be specified; these will be used as
    placeholders in the input fields.
    ###
    addField: (inputIndex, name, defaultKey, defaultValue) =>
      if !(defaultKey?) then defaultKey = "property"
      if !(defaultValue?) then defaultValue = "value"
      $row = $ """
          <div id="#{name}Div#{inputIndex}" class="#{name}Div">
          <input style="width:80px" name="property#{name}#{inputIndex}" placeholder="#{defaultKey}" class="property#{name}">
          <input style="width:80px" name="value#{name}#{inputIndex}" placeholder="#{defaultValue}" class="value#{name}">
          <input type="button" id="remove#{name}#{inputIndex}" value="x" onclick="this.parentNode.parentNode.removeChild(this.parentNode);">
          </div>
      """
      $("##{name}Form").append $row

    ###
    Takes the input form /form_name/ and populates a propertyObject with the
    property-value pairs contained in it, checking the property names for
    legality in the process
    Returns: [submitOK, {property1: value1, property2: value2, ...}], where
             /submitOK/ is a boolean indicating whether all property names are
             legal
    ###
    assign_properties: (form_name, is_illegal = @dataController.is_illegal) => 
        submitOK = true
        propertyObject = {}
        createDate = new Date()
        propertyObject["_Creation_Date"] = createDate
        if not ($("##{form_name}Name").val() == undefined or $("##{form_name}Name").val() == "")
          propertyObject["name"] = $("##{form_name}Name").val().replace(/'/g, "\\'")
        if not ($("##{form_name}Desc").val() == undefined or $("##{form_name}Desc").val() == "")
          propertyObject["description"] = $("##{form_name}Desc").val().replace(/'/g, "\\'")
        #if not ($("##{form_name}Color").val() == undefined or $("##{form_name}Color").val() == "")
        #  propertyObject["color"] = $("##{form_name}Color").val().replace(/'/g, "\\'")
        #if not ($("##{form_name}Size").val() == undefined or $("##{form_name}Size").val() == "")
        #  propertyObject["size"] = $("##{form_name}Size").val().replace(/'/g, "\\'")
        if not ($("##{form_name}Url").val() == undefined or $("##{form_name}Url").val() == "")
          propertyObject["url"] = $("##{form_name}Url").val().replace(/'/g, "\\'")
        $("." + form_name + "Div").each (i, obj) ->
            property = $(this).children(".property" + form_name).val()
            value = $(this).children(".value" + form_name).val()
            # check whether property name is allowed and ensure that user does not
            # accidentally assign the same property twice
            # - if property name is not ok, there is an apropriate error message and
            #   node creation is cancelled
            # - if property name is ok, property-value pair is assigned to the
            #   nodeObject, escaping any single quotes in the value so they don't
            #   break the cypher query
            if is_illegal(property, "Property")
              alert "Property '" + property + "' is not allowed."
              submitOK = false
            else if property of propertyObject
              alert "Property '" + property + "' already assigned.\nFirst value: " + propertyObject[property] + "\nSecond value: " + value
              submitOK = false
            else
              propertyObject[property] = value.replace(/'/g, "\\'")
        [submitOK, propertyObject];

    ###
    Creates a node using the information in @$nodeInputName, @$nodeInputDesc,
    and NodeCreateDiv; resets the input forms if creation is successful
    ###
    createNode: =>
      # check property names and assign property-value pairs to nodeObject;
      # first component of nodeObject is boolean result of whether all
      # properties are legal, second component is dictionary of properties to
      # be assigned
      nodeObject = @assign_properties("NodeCreate")
      # if all property names were fine, remove the on-the-fly created input
      # fields and submit the data to the server to actually create the node
      if (nodeObject[0] and (_.size(nodeObject[1]) > 1 or confirm "The node you are creating has no information associated with it. Do you really want to proceed?")) then (
        $('.NodeCreateDiv').each( (i, obj) ->
          $(this)[0].parentNode.removeChild $(this)[0]
        )
        @$nodeInputName.val('')
        @$nodeInputDesc.val('')
        #@$nodeInputColor.val('')
        @$nodeInputUrl.val('')
        #@$nodeInputSize.val('')
        @$nodeInputName.focus()
        @dataController.nodeAdd(nodeObject[1], (datum) =>
          datum.fixed = true
          datum.px = ($(window).width()/2-@graphView.currentTranslation[0])/@graphView.currentScale
          datum.py = ($(window).height()/2-@graphView.currentTranslation[1])/@graphView.currentScale
          @graphModel.putNode(datum)
          @selection.toggleSelection(datum)
        )
      )


    ###
    ###
    buildLink: =>
      # check property names and assign property-value pairs
      # first component of relProperties is boolean result of whether all
      # properties are legal; second component is dictionary of properties to
      # be assigned
      console.log "Building Link"
      linkProperties = @assign_properties("LinkCreate")

      # if all property names were fine, remove the on-the-fly created input
      # fields and submit the data to the server to actually create the link
      if linkProperties[0]
        @tempLink["properties"] = linkProperties[1]
        @buildingLink = true
        $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">Click a node to select it as the link source.</span>')
        @$createLinkButton.val('Cancel Link Creation')

    ###
    To Do: replace this with a "to string" method for nodes
    ###
    findHeader: (node) ->
      if node.name?
        node.name
      else if node.title?
        node.title
      else
        ''
