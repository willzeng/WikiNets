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
              <input style="width:80px" id="LinkCreateType" value="type" />
            </form>
          </div>
        """
      $container.appendTo @$el

      nodeInputNumber = 0
      linkInputNumber = 0

      $nodeMoreFields = $("<input id=\"moreNodeCreateFields\" type=\"button\" value=\"+\">").appendTo("#NodeCreateContainer")
      $nodeMoreFields.click(() => 
        @addField(nodeInputNumber, "NodeCreate")
        nodeInputNumber = nodeInputNumber+1
        )

      $nodeCreate = $("<input id=\"NodeCreateButton\" type=\"button\" value=\"Create node\">").appendTo("#NodeCreateContainer")
      $nodeCreate.click(@createNode)

      $linkCreateSelectSourceButton = $("<input id=\"LinkCreateSource\" type=\"button\" value=\"Source:\" />").appendTo("#LinkCreateSelectSource")
      $linkCreateSelectSourceButton.click(() =>
        console.log "selecting source"
        $("#LinkCreateSourceValue").replaceWith("<span id=\"LinkCreateSourceValue\" style=\"font-style:italic;\">Selecting</span>")
        @selectingSource = true
        )

      $linkCreateSelectTargetButton = $("<input id=\"LinkCreateTarget\" type=\"button\" value=\"Target:\" />").appendTo("#LinkCreateSelectTarget")
      $linkCreateSelectTargetButton.click(() =>
        console.log "selecting target"
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
        console.log "node selected"
        if @selectingSource
          console.log "Source: " + node["_id"]
          $("#LinkCreateSourceValue").replaceWith("<span id=\"LinkCreateSourceValue\">" + node["text"] + " (id: " + node["_id"] + ")</span>")
          @selectingSource = false
          @source = node
        if @selectingTarget
          console.log "Target: " + node["_id"]
          $("#LinkCreateTargetValue").replaceWith("<span id=\"LinkCreateTargetValue\">" + node["text"] + " (id: " + node["_id"] + ")</span>")
          @selectingTarget = false
          @target = node

      @graphView.on "view:rightclick", () => 
        pluginsList = @layout.pluginWrappers[key] for own key, value of @layout.pluginWrappers
        createPlugin = plugin for plugin in pluginsList when plugin.pluginName is "Create"
        #uncollapse the Create menu if it is collapsed
        if createPlugin.collapsed then createPlugin.close() 
        #automatically add and fill a name field
        if nodeInputNumber is 0
          @addField(nodeInputNumber, "NodeCreate", "Name", "")
          #$('valueNodeCreate0').focus() #THIS DOESN'T QUITE WORK
          nodeInputNumber = nodeInputNumber+1




      return this


    # should come up with a better naming scheme really...
    addField: (inputIndex, name) =>
      $row = $ """
          <div id="#{name}Div#{inputIndex}" class="#{name}Div">
          <input style="width:80px" name="property#{name}#{inputIndex}" value="propertyEx" class="property#{name}">
          <input style="width:80px" name="value#{name}#{inputIndex}" value="valueEx" class="value#{name}">
          <input type="button" id="remove#{name}#{inputIndex}" value="x" onclick="this.parentNode.parentNode.removeChild(this.parentNode);">
          </div>
      """
      $("##{name}Form").append $row

    addField: (inputIndex, name, defaultKey, defaultValue) =>
      $row = $ """
          <div id="#{name}Div#{inputIndex}" class="#{name}Div">
          <input style="width:80px" name="property#{name}#{inputIndex}" value="#{defaultKey}" class="property#{name}">
          <input style="width:80px" name="value#{name}#{inputIndex}" value="#{defaultValue}" class="value#{name}">
          <input type="button" id="remove#{name}#{inputIndex}" value="x" onclick="this.parentNode.parentNode.removeChild(this.parentNode);">
          </div>
      """
      $("##{name}Form").append $row


    createNode: =>
      console.log "create node called"
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
      console.log "create link called"
      # relationships must have a beginning and end node (given by ID) and a
      # type; beginning and end node IDs must be numbers; relationship type
      # must obey same rules as property names
      # if any of these conditions are not satisfied, the user is informed and
      # relationship creation is cancelled
      if @source == undefined or @target == undefined or @selectingSource or @selectingTarget
        alert "Please select a source and a target."
        return false
      if @is_illegal($("#LinkCreateType").val(), "Relationship type")
        return false
      console.log "source, target, type are OK"
      linkObject =
        source: @source
        target: @target 
      console.log linkObject
  
      # check property names and assign property-value pairs
      # first component of relProperties is boolean result of whether all
      # properties are legal; second component is dictionary of properties to
      # be assigned
      linkProperties = @assign_properties("LinkCreate")
      linkProperties[1]["name"] = $("#LinkCreateType").val()

      # if all property names were fine, remove the on-the-fly created input
      # fields and submit the data to the server to actually create the link
      if (linkProperties[0]) then (
        console.log "properties are OK"
        $('.LinkCreateDiv').each( (i, obj) ->
          $(this)[0].parentNode.removeChild $(this)[0]
        )
        $("#LinkCreateSourceValue").replaceWith("<span id=\"LinkCreateSourceValue\"></span>")
        $("#LinkCreateTargetValue").replaceWith("<span id=\"LinkCreateTargetValue\"></span>")
        @source = undefined
        @target = undefined
        $("#LinkCreateType").val("Type")
        linkObject["properties"] = linkProperties[1]
        console.log linkObject
        @dataController.linkAdd(linkObject, (linkres)=> 
          console.log "called dataController.linkAdd"
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
    assign_properties: (form_name, is_illegal = @is_illegal) => 
        submitOK = true
        propertyObject = {}
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


    # checks whether property names will break the cypher queries or are any of
    # the reserved terms
    is_illegal: (property, type) ->
      reserved_keys = ["_id", "name"]
      if (property == '') then (
        alert type + " name must not be empty." 
        return true
      ) else if (/^.*[^a-zA-Z0-9_].*$/.test(property)) then (
        alert(type + " name '" + property + "' illegal: " + type + " names must only contain alphanumeric characters and underscore.")
        return true
      ) else if (reserved_keys.indexOf(property) != -1) then (
        alert(type + " name illegal: '" + property + "' is a reserved term.")
        return true
      ) else false

