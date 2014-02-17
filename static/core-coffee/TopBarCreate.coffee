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
      @selection.on "change", @update.bind(this)

    render: ->

      $container = $('<div id="topbarcreate">').appendTo $('#buildbar')

      $nodeSide = $('<div id="nodeside">').appendTo $container

      $nodeHolder = $('<textarea placeholder="Add Node" id="nodeHolder" name="textin" rows="1" cols="35"></textarea>').appendTo $nodeSide

      @$nodeWrapper = $('<div id="NodeCreateContainer">').appendTo $nodeSide

      @$nodeInputName = $('<textarea id="NodeCreateName" placeholder=\"Node Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper
      @$nodeInputDesc = $('<textarea id="NodeCreateDesc" placeholder="Description [optional]" rows="1" cols="35"></textarea><br>').appendTo @$nodeWrapper

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
              )
            @sourceSet = @buildingLink = false
            $('#toplink-instructions').replaceWith('<span id="toplink-instructions"></span>')
            $linkHolder.show()
          else
            @tempLink.source = node
            @sourceSet = true
            $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">Click a node to select it as the link target.</span>')

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
        console.log $("##{form_name}Name").val(), $("##{form_name}Desc").val()
        if not ($("##{form_name}Name").val() == undefined or $("##{form_name}Name").val() == "")
          propertyObject["name"] = $("##{form_name}Name").val().replace(/'/g, "\\'")
        if not ($("##{form_name}Desc").val() == undefined or $("##{form_name}Desc").val() == "")
          propertyObject["description"] = $("##{form_name}Desc").val().replace(/'/g, "\\'")
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
      if (nodeObject[0]) then (
        $('.NodeCreateDiv').each( (i, obj) ->
          $(this)[0].parentNode.removeChild $(this)[0]
        )
        @$nodeInputName.val('')
        @$nodeInputDesc.val('')
        @$nodeInputName.focus()
        @dataController.nodeAdd(nodeObject[1], (datum) => @graphModel.putNode(datum))
      )

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
