# allows creation of nodes and arrows in the database using DataController
define [], () ->

  class Create extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      # require various plugins:
      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']
      @dataController = instances['local/Neo4jDataController']
      @layout = instances["Layout"]

      @layout.addPlugin @el, @options.pluginOrder, 'Create'

      @render()

    render: () ->
      $container = $ """
          <div id="NodeCreateContainer">
            Create Node: 
            <form id="NodeCreateForm">
            </form>
          </div>
          <div id="LinkCreateContainer">
            Create Link: 
            <form id="LinkCreateForm">
              <span id="LinkCreateSelectSource"></span>
              <span id="LinkCreateSourceValue"></span><br />
              <span id="LinkCreateSelectTarget"></span>
              <span id="LinkCreateTargetValue"></span><br />
              <input style="width:80px" id="LinkCreateType" placeholder="Type" />
            </form>
          </div>
        """
      $container.appendTo @$el

      nodeInputNumber = 0
      linkInputNumber = 0

      $nodeMoreFields = $("<input id=\"moreNodeCreateFields\" type=\"button\" value=\"+\">").appendTo("#NodeCreateContainer")
      $nodeMoreFields.click(() => 
        if $('.NodeCreateDiv').length is 0
          @addField(nodeInputNumber, "NodeCreate", "name", "")
        else
          @addField(nodeInputNumber, "NodeCreate")
        nodeInputNumber = nodeInputNumber+1
        )

      $nodeCreate = $("<input id=\"NodeCreateButton\" type=\"button\" value=\"Create node\">").appendTo("#NodeCreateContainer")
      $nodeCreate.click(@createNode)

      $linkCreateSelectSourceButton = $("<input id=\"LinkCreateSource\" type=\"button\" value=\"Source:\" />").appendTo("#LinkCreateSelectSource")
      $linkCreateSelectSourceButton.click(() =>
        $("#LinkCreateSourceValue").replaceWith("<span id=\"LinkCreateSourceValue\" style=\"font-style:italic;\">Selecting</span>")
        @selectingSource = true
        )

      $linkCreateSelectTargetButton = $("<input id=\"LinkCreateTarget\" type=\"button\" value=\"Target:\" />").appendTo("#LinkCreateSelectTarget")
      $linkCreateSelectTargetButton.click(() =>
        $("#LinkCreateTargetValue").replaceWith("<span id=\"LinkCreateTargetValue\" style=\"font-style:italic;\">Selecting</span>")
        @selectingTarget = true
        )

      $linkMoreFields = $("<input id=\"moreLinkCreateFields\" type=\"button\" value=\"+\">").appendTo("#LinkCreateContainer")
      $linkMoreFields.click(() => 
        @addField(linkInputNumber, "LinkCreate")
        linkInputNumber = linkInputNumber+1
        )

      $linkCreate = $("<input id=\"LinkCreateButton\" type=\"button\" value=\"Create link\">").appendTo("#LinkCreateContainer")
      $linkCreate.click(@createLink)

      selectingSource = false
      selectingTarget = false

      @graphView.on "enter:node:click", (node) =>
        if @selectingSource
          $("#LinkCreateSourceValue").replaceWith("<span id=\"LinkCreateSourceValue\">" + @graphView.findText(node) + " (id: " + node["_id"] + ")</span>")
          @selectingSource = false
          @source = node
        if @selectingTarget
          $("#LinkCreateTargetValue").replaceWith("<span id=\"LinkCreateTargetValue\">" + @graphView.findText(node) + " (id: " + node["_id"] + ")</span>")
          @selectingTarget = false
          @target = node

      @graphView.on "view:rightclick", () => 
        pluginsList = @layout.pluginWrappers[key] for own key, value of @layout.pluginWrappers
        createPlugin = plugin for plugin in pluginsList when plugin.pluginName is "Create"
        #uncollapse the Create menu if it is collapsed
        if createPlugin.collapsed then createPlugin.close() 
        #automatically add and fill a name field
        if $('.NodeCreateDiv').length is 0
          @addField(nodeInputNumber, "NodeCreate", "name", "")
          #$('valueNodeCreate0').focus() #THIS DOESN'T QUITE WORK
          nodeInputNumber = nodeInputNumber+1

      return this

    addField: (inputIndex, name, defaultKey, defaultValue) =>
      if !(defaultKey?) then defaultKey = "propertyEx"
      if !(defaultValue?) then defaultValue = "valueEx"
      $row = $ """
          <div id="#{name}Div#{inputIndex}" class="#{name}Div">
          <input style="width:80px" name="property#{name}#{inputIndex}" placeholder="#{defaultKey}" class="property#{name}">
          <input style="width:80px" name="value#{name}#{inputIndex}" placeholder="#{defaultValue}" class="value#{name}">
          <input type="button" id="remove#{name}#{inputIndex}" value="x" onclick="this.parentNode.parentNode.removeChild(this.parentNode);">
          </div>
      """
      $("##{name}Form").append $row


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
        @dataController.nodeAdd(nodeObject[1], (datum) => @graphModel.putNode(datum))
      )


    createLink: =>
      # relationships must have a beginning and end node (given by ID) and a
      # type; beginning and end node IDs must be numbers; relationship type
      # must obey same rules as property names
      # if any of these conditions are not satisfied, the user is informed and
      # relationship creation is cancelled
      if @source == undefined or @target == undefined or @selectingSource or @selectingTarget
        alert "Please select a source and a target."
        return false
      if @dataController.is_illegal($("#LinkCreateType").val(), "Relationship type")
        return false
      linkObject =
        source: @source
        target: @target 
  
      # check property names and assign property-value pairs
      # first component of relProperties is boolean result of whether all
      # properties are legal; second component is dictionary of properties to
      # be assigned
      linkProperties = @assign_properties("LinkCreate")
      linkProperties[1]["name"] = $("#LinkCreateType").val()

      # if all property names were fine, remove the on-the-fly created input
      # fields and submit the data to the server to actually create the link
      if (linkProperties[0]) then (
        $('.LinkCreateDiv').each( (i, obj) ->
          $(this)[0].parentNode.removeChild $(this)[0]
        )
        $("#LinkCreateSourceValue").replaceWith("<span id=\"LinkCreateSourceValue\"></span>")
        $("#LinkCreateTargetValue").replaceWith("<span id=\"LinkCreateTargetValue\"></span>")
        @source = undefined
        @target = undefined
        $("#LinkCreateType").val("")
        $("#LinkCreateType").attr("placeholder", "Type")
        linkObject["properties"] = linkProperties[1]
        @dataController.linkAdd(linkObject, (linkres)=> 
          newLink = linkres
          allNodes = @graphModel.getNodes()
          newLink.source = n for n in allNodes when n['_id'] is linkObject.source['_id']
          newLink.target = n for n in allNodes when n['_id'] is linkObject.target['_id']
          @graphModel.putLink(newLink)
          )
      )
      

    # takes a form and populates a propertyObject with the property-value pairs
    # contained in it, checking the property names for legality in the process
    # returns: submitOK: a boolean indicating whether the property names were all
    #                    legal
    #          propertyObject: a dictionary of property-value pairs
    assign_properties: (form_name, is_illegal = @dataController.is_illegal) => 
        submitOK = true
        propertyObject = {}
        createDate = new Date()
        propertyObject["Creation_Date"]=createDate
        $("." + form_name + "Div").each (i, obj) ->
            property = $(this).children(".property" + form_name).val()
            value = $(this).children(".value" + form_name).val()
            # check whether property name is allowed and ensure that user does not
            # accidentally assign the same property twice
            # - if property name is not ok, there is an apropriate error message and
            #   node creation is cancelled
            # - if property name is ok, property-value pair is assigned to the
            #   nodeObject, escaping any single quotes in the value so they don't
            #  break the cypher query
            if is_illegal(property, "Property")
              submitOK = false
            else if property of propertyObject
              alert "Property '" + property + "' already assigned.\nFirst value: " + propertyObject[property] + "\nSecond value: " + value
              submitOK = false
            else
              propertyObject[property] = value.replace(/'/g, "\\'")
        [submitOK, propertyObject];