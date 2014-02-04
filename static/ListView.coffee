# provides a list of the nodes
define [], () ->

  class ListView extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      #require plugins
      @dataController = instances['local/Neo4jDataController']

      @graphModel = instances['GraphModel']
      @graphModel.on "change", @update.bind(this)

      @listenTo instances["KeyListener"], "down:80", () => @$el.toggle()
      #instances["Layout"].addCenter @el
      $(@el).appendTo $('#maingraph')

      $(@el).hide()

    update: ->
      @$el.empty()
      allNodes = @graphModel.getNodes()

      $container = $("<div class=\"listview-profile-helper\"/>").appendTo(@$el)
      _.each allNodes, (node) =>
        @addNode(node, $container)

    addNode: (node, parent) =>
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]

      $nodeDiv = $("<div class=\"node-profile\"/>").appendTo(parent)
      header = @findHeader(node)
      $("<div class=\"node-profile-title\">#{header}</div>").appendTo $nodeDiv
      _.each node, (value, property) ->
        value += ""
        if blacklist.indexOf(property) < 0
          if value?
            makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi,"<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>")
          else
            makeLinks = value
          if property!="color"
            $("<div class=\"node-profile-property\">#{property}:  #{makeLinks}</div>").appendTo $nodeDiv  
      
      $nodeEdit = $("<input id=\"NodeEditButton#{node['_id']}\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this node\"><br>").appendTo $nodeDiv
      $nodeEdit.click(() =>
        @editNode(node, $nodeDiv, blacklist)
        )

      allLinks = @graphModel.getLinks()
      nodeHash = @graphModel.get("nodeHash")
      neighbors = (link.target for link in allLinks when nodeHash(link.source) is nodeHash(node))
      _.each neighbors, (neighbor) =>
        $nButton = $("<span class=\"node-profile-neighbor\">#{@findHeader(neighbor)}</span>").appendTo $nodeDiv
        $nButton.click () =>
          @addNode(neighbor, $nodeDiv)
        $linkProfile = $("<div class=\"node-profile\">")
        $linkProfile.appendTo $nButton
        link = link for link in allLinks when (nodeHash(link.source) is nodeHash(node)) and (nodeHash(link.target) is nodeHash(neighbor))
        _.each link, (value, property) ->
          $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $linkProfile
        $linkProfile.hide()
        $nButton.mouseenter () =>
          $linkProfile.show()
        $nButton.mouseleave () =>
          $linkProfile.hide()

      neighbors = (link.source for link in allLinks when nodeHash(link.target) is nodeHash(node))
      _.each neighbors, (neighbor) =>
        $nButton = $("<span class=\"node-profile-neighbor\">#{@findHeader(neighbor)}</span>").appendTo $nodeDiv
        $nButton.click () =>
          @addNode(neighbor, $nodeDiv)
        $linkProfile = $("<div class=\"node-profile\">")
        $linkProfile.appendTo $nButton
        link = link for link in allLinks when (nodeHash(link.source) is nodeHash(node)) and (nodeHash(link.target) is nodeHash(neighbor))
        _.each link, (value, property) ->
          $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $linkProfile
        $linkProfile.hide()
        $nButton.mouseenter () =>
          $linkProfile.show()
        $nButton.mouseleave () =>
          $linkProfile.hide()

    editNode: (node, nodeDiv, blacklist) ->
          console.log "Editing node: " + node['_id']
          nodeInputNumber = 0

          #TODO these color settings should probably go in a settings plugin
          origColor = "#A9A9A9" #TODO: map this to the CSS file color choice for node color
          colors = ["darkgray", "aqua", "black", "blue", "darkblue", "fuchsia", "green", "darkgreen", "lime", "maroon", "navy", "olive", "orange", "purple", "red", "silver", "teal", "yellow"]
          hexColors = ["#A9A9A9","#00FFFF","#000000","#0000FF", "#00008B","#FF00FF","#008000","#006400","#00FF00","#800000","#000080","#808000","#FFA500","#800080","#FF0000","#C0C0C0","#008080","#FFFF00"]
          
          header = @findHeader(node)

          nodeDiv.html("<div class=\"node-profile-title\">Editing #{header} (id: #{node['_id']})</div><form id=\"Node#{node['_id']}EditForm\"></form>")
          _.each node, (value, property) ->
            if blacklist.indexOf(property) < 0 and ["_id", "text"].indexOf(property) < 0 and property!="color"
              newEditingFields = """
                <div id=\"Node#{node['_id']}EditDiv#{nodeInputNumber}\" class=\"Node#{node['_id']}EditDiv\">
                  <input style=\"width:80px\" id=\"Node#{node['_id']}EditProperty#{nodeInputNumber}\" value=\"#{property}\" class=\"propertyNode#{node['_id']}Edit\"/> 
                  <input style=\"width:80px\" id=\"Node#{node['_id']}EditValue#{nodeInputNumber}\" value=\"#{value}\" class=\"valueNode#{node['_id']}Edit\"/> 
                  <input type=\"button\" id=\"removeNode#{node['_id']}Edit#{nodeInputNumber}\" value=\"x\" onclick=\"this.parentNode.parentNode.removeChild(this.parentNode);\">
                </div>
              """
              $(newEditingFields).appendTo("#Node#{node['_id']}EditForm")
              nodeInputNumber = nodeInputNumber + 1
            else if property == "color"
              if value in colors 
                origColor = hexColors[colors.indexOf(value)]
              else if origColor in hexColors 
                origColor = value

          colorEditingField = '
            <form action="#" method="post">
                <div class="controlset">Color<input id="color'+node['_id']+'" name="color'+node['_id']+'" type="text" value="'+origColor+'"/></div>
            </form>
          '
          $(colorEditingField).appendTo(nodeDiv)

          $("#color#{node['_id']}").colorPicker {showHexField: false} 


          $nodeMoreFields = $("<input id=\"moreNode#{node['_id']}EditFields\" type=\"button\" value=\"+\">").appendTo(nodeDiv)
          $nodeMoreFields.click(() =>
            @addField(nodeInputNumber, "Node#{node['_id']}Edit")
            nodeInputNumber = nodeInputNumber+1
          )


          $nodeSave = $("<input name=\"nodeSaveButton\" type=\"button\" value=\"Save\">").appendTo(nodeDiv)
          $nodeSave.click () => 
            newNodeObj = @assign_properties("Node#{node['_id']}Edit", $("#color"+node['_id']).val())
            if newNodeObj[0]
              newNode = newNodeObj[1]
              newNode['_id'] = node['_id']
              @dataController.nodeEdit(node,newNode, (savedNode) =>           
                @graphModel.filterNodes (node) ->
                  !(savedNode['_id'] == node['_id'])
                @graphModel.putNode(savedNode)
                @cancelEditing(savedNode, nodeDiv, blacklist)
              )

          $nodeDelete = $("<input name=\"NodeDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(nodeDiv)
          $nodeDelete.click () => 
            if confirm("Are you sure you want to delete this node?") then @deleteNode(node, -> )

          $nodeCancel =  $("<input name=\"NodeCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(nodeDiv)
          $nodeCancel.click () => @cancelEditing(node, nodeDiv, blacklist)

    cancelEditing: (node, nodeDiv, blacklist) =>
      nodeDiv.html("<div class=\"node-profile-title\">#{@findHeader(node)}</div>")
      _.each node, (value, property) ->
        $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo nodeDiv  if blacklist.indexOf(property) < 0
      $nodeEdit = $("<input id=\"NodeEditButton#{node['_id']}\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this node\">").appendTo nodeDiv
      $nodeEdit.click(() =>
        @editNode(node, nodeDiv, blacklist)
        )

    deleteNode: (delNode, callback)=>
      @dataController.nodeDelete delNode, (response) =>
        if response == "error"
          if confirm("Could not delete node. There might be links remaining on this node. Do you want to delete the node (and all links to it) anyway?")
            @dataController.nodeDeleteFull delNode, (responseFull) => 
              console.log "Node Deleted"
              @graphModel.filterNodes (node) ->
                !(delNode['_id'] == node['_id'])
              callback()
        else
          console.log "Node Deleted"
          @graphModel.filterNodes (node) ->
            !(delNode['_id'] == node['_id'])
          callback()

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

    # takes a form and populates a propertyObject with the property-value pairs
    # contained in it, checking the property names for legality in the process
    # returns: submitOK: a boolean indicating whether the property names were all
    #                    legal
    #          propertyObject: a dictionary of property-value pairs
    assign_properties: (form_name, colorValue, is_illegal = @dataController.is_illegal) => 
        submitOK = true
        propertyObject = {}
        propertyObject["color"] = colorValue
        $("."+ form_name + "Div").each (i, obj) ->
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

        [submitOK, propertyObject]

    findHeader: (node) ->
      if node.name?
        node.name
      else if node.title?
        node.title
      else
        ''

