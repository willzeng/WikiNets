# allows creation of nodes and arrows in the database using DataController
define [], () ->

  class Create extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->

      _.extend this, Backbone.Events

      @graphView = instances['GraphView']
      @graphModel = instances['GraphModel']
      @dataController = instances['local/Neo4jDataController']

      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Create'

      @render()

    render: () ->
      $container = $ """
          <div class="create-container">
            Create Node: 
            <table border="0">
            </table>
          </div>
        """
      $container.appendTo @$el

      @nodeInputNumber = 0

      $nodeMoreFields = $("<input id=\"moreFields\" type=\"button\" value=\"+\">").appendTo($container)
      $nodeMoreFields.click(() => 
        @nodeInputNumber = @nodeInputNumber+1
        @updateFields()
        )

      $nodeCreate = $("<input id=\"createObj\" type=\"button\" value=\"Create node\">").appendTo($container)
      $nodeCreate.click(@createNode)

      return this

    updateFields: =>
      @$("table").empty()
      @addNodeField() for num in [1..@nodeInputNumber]

    addNodeField: =>
      $row = $ """
        <tr>
          <td><input style=\"width:80px\" name=\"propertyNode\" value=\"propertyEx\" class=\"propertyNode\">
          <input style=\"width:80px\" name=\"valueNode\" value=\"valueEx\" class=\"valueNode\">
          <input type=\"button\" id=\"removeRow\" value=\"x\">
          </td>
        </tr>
      """
      
      #TODO This does not yet work
      # @$("removeRow").click(() => 
      #   @nodeInputNumber = @nodeInputNumber-1
      #   @updateFields()
      #   )

      @$("table").append $row

    createNode: =>
      console.log "create node called"
      # check property names and assign property-value pairs to nodeObject
      # first component of nodeObject is boolean result of whether all
      # properties are legal; second component is dictionary of properties to
      # be assigned
      nodeObject = @assign_properties("Node")
      # if all property names were fine, remove the on-the-fly created input
      # fields and submit the data to the server to actually create the node
      if (nodeObject[0]) then (
        $('.NodeProperty').each( (i, obj) ->
          $(this)[0].parentNode.removeChild $(this)[0]
        )
        console.log(JSON.stringify(nodeObject[1]));

        console.log "CALL THE SERVER TO MAKE A NODE", nodeObject[1])
        #@dataController.addNode nodeObject[1] 
      

    # takes a form and populates a propertyObject with the property-value pairs
    # contained in it, checking the property names for legality in the process
    # returns: submitOK: a boolean indicating whether the property names were all
    #                    legal
    #          propertyObject: a dictionary of property-value pairs
    assign_properties: (form_name) => 
        submitOK = true
        propertyObject = {}
        $("." + form_name + "Property").each( (i, obj) =>
            property = $(this).children(".property" + form_name).val()
            value = $(this).children(".value" + form_name).val()
            # check whether property name is allowed and ensure that user does not
            # accidentally assign the same property twice
            # - if property name is not ok, there is an apropriate error message and
            #   node creation is cancelled
            # - if property name is ok, property-value pair is assigned to the
            #   nodeObject, escaping any single quotes in the value so they don't
            #  break the cypher query
            if @is_illegal(property, "Property") then submitOK = false
            else if (property in propertyObject) then (
              alert("Property '" + property + "' already assigned.\nFirst value: " + propertyObject[property] + "\nSecond value: " + value)
              submitOK = false
            ) #else propertyObject[property] = value.replace(/'/g, "\\'")
        )
        return [submitOK, propertyObject];


    # checks whether property names will break the cypher queries or are any of
    # the reserved terms
    is_illegal: (property, type) ->
      if (property == '') then (
        alert type+" name must not be empty." 
        return true
      ) else if (/^.*[^a-zA-Z0-9_].*$/.test(property)) then (
        alert(type + " name '" + property + "' illegal: " + type + " names must only contain alphanumeric characters and underscore.")
        return true
      ) else if (reserved_keys.indexOf(property) != -1) then (
        alert(type + " name illegal: '" + property + "' is a reserved term.")
        return true
      ) else false
    
    