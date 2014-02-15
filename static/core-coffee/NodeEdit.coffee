# provides details of the selected nodes
define [], () ->

  class NodeEdit extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      
      #require plugins
      @dataController = instances['local/Neo4jDataController']

      @graphModel = instances['GraphModel']
      @graphView = instances['GraphView']
      @graphModel.on "change", @update.bind(this)

      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)
      @listenTo instances["KeyListener"], "down:80", () => @$el.toggle()
      
      #place the plugin on the whole window
      $(@el).appendTo $('#omniBox')

    update: ->
      if !@buildingLink
        @$el.empty()
        selectedNodes = @selection.getSelectedNodes()
        $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
        #these are they peoperties that are not shown in the profile
        blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight", "_id", "color"]
        _.each selectedNodes, (node) =>
          $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
          @renderProfile(node, $nodeDiv, blacklist, 4) 

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
            if blacklist.indexOf(property) < 0 and ["_id", "text", "color", "_Last_Edit_Date", "_Creation_Date"].indexOf(property) < 0
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
            newNodeObj = @assign_properties("Node#{node['_id']}Edit")
            if newNodeObj[0]
              newNode = newNodeObj[1]
              newNode['color'] = $("#color"+node['_id']).val()
              newNode['_id'] = node['_id']
              newNode['_Creation_Date'] = node['_Creation_Date']
              @dataController.nodeEdit(node,newNode, (savedNode) =>           
                @graphModel.filterNodes (node) ->
                  !(savedNode['_id'] == node['_id'])
                @graphModel.putNode(savedNode)
                @selection.toggleSelection(savedNode)
                @cancelEditing(savedNode, nodeDiv, blacklist)
              )

          $nodeDelete = $("<input name=\"NodeDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(nodeDiv)
          $nodeDelete.click () => 
            if confirm("Are you sure you want to delete this node?") then @deleteNode(node, () => @selection.toggleSelection(node))

          $nodeCancel =  $("<input name=\"NodeCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(nodeDiv)
          $nodeCancel.click () => @cancelEditing(node, nodeDiv, blacklist)

    cancelEditing: (node, nodeDiv, blacklist) =>
      nodeDiv.empty()
      @renderProfile(node, nodeDiv, blacklist)

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
    assign_properties: (form_name, is_illegal = @dataController.is_illegal) => 
        submitOK = true
        propertyObject = {}
        editDate = new Date()
        propertyObject["_Last_Edit_Date"]=editDate
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

    #this method chooses the header from a node
    #TODO would be to define a .toString method for nodes
    findHeader: (node) ->
      if node.name?
        node.name
      else if node.title?
        node.title
      else
        ''

    #displays the profile of a selected node
    renderProfile: (node, nodeDiv, blacklist, propNumber) =>
      nodeDiv.empty()
      header = @findHeader(node)
      
      #add the header and the edit icon
      $nodeHeader = $("<div class=\"node-profile-title\">#{header}</div>").appendTo nodeDiv
      $nodeEdit = $("<i class=\"fa fa-pencil-square-o\"></i>").prependTo $nodeHeader

      #adds the deselect button
      $nodeDeselect = $("<i class=\"right fa fa-times\"></i>").appendTo $nodeHeader
      $nodeDeselect.click () => @selection.toggleSelection(node)

      whitelist = ["description", "url"]

      #only show the first four properties initially
      nodeLength = 0
      for p,v of node
        if !(p in blacklist)
          nodeLength = nodeLength+1

      counter = 0
      _.each node, (value, property) ->
        if counter >= propNumber
          return
        value += ""
        if blacklist.indexOf(property) < 0
          if value?
            makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi,"<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>")
          else
            makeLinks = value
          if property in whitelist
            $("<div class=\"node-profile-property\">#{makeLinks}</div>").appendTo nodeDiv 
          else if property == "_Last_Edit_Date" or property=="_Creation_Date"
            $("<div class=\"node-profile-property\">#{property}:  #{makeLinks.substring(4,21)}</div>").appendTo nodeDiv  
          else
            $("<div class=\"node-profile-property\">#{property}:  #{makeLinks}</div>").appendTo nodeDiv
          counter++ 

      $nodeEdit.click () =>
        @editNode(node, nodeDiv, blacklist)

      if propNumber < nodeLength
        $showMore = $("<div class=\"node-profile-property\"><a href='#'>Show More...</a></div>").appendTo nodeDiv 
        $showMore.click () =>
          @renderProfile(node, nodeDiv, blacklist, propNumber+1)

      @addLinker node, nodeDiv

    addLinker: (node, nodeDiv) =>
      @tempLink = {}
      #@tempLink.source = node

      nodeID = node['_id']

      linkSideID = "id=" + "'linkside" + nodeID + "'"
      $linkSide = $('<div ' + linkSideID + '>').appendTo nodeDiv
      
      holderClassName = "'profilelinkHolder" + nodeID + "'"
      className = "class=" + holderClassName
      $linkHolder = $('<textarea placeholder="Add Link" ' + className + 'rows="1" cols="35"></textarea><br>')
        .css("width",100)
        .css("margin-left",85)
        # .css("margin",0)
        # .css("margin-left","auto")
        # .css("margin-right","auto")
        # .css("position","relative")
        # .css("align","center")
        .appendTo $linkSide

      linkWrapperDivID = "id=" + "'source-container" + nodeID + "'"
      $linkWrapper = $('<div ' + linkWrapperDivID + '>').appendTo $linkSide
      #$linkTitleArea = $('<textarea placeholder="Title" id="nodeTitle" name="textin" rows="1" cols="35"></textarea><br>').appendTo @$linkWrapper
      # $linkInput = $('<textarea placeholder="Link : A link\'s description #key1 value1 #key2 value2" id="linkInputField" name="textin" rows="5" cols="35"></textarea><br>').appendTo @$linkWrapper
      $linkInputName = $('<textarea placeholder=\"Link Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo $linkWrapper
      $linkInputUrl = $('<textarea placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo $linkWrapper
      $linkInputDesc = $('<textarea placeholder="Description\n #key1 value1 #key2 value2" rows="5" cols="35"></textarea><br>').appendTo $linkWrapper

      $createLinkButton = $('<input type="submit" value="Create Link"><br>').appendTo $linkWrapper

      $createLinkButton.click () =>
        @tempLink.source = node
        @buildLink(
          @parseSyntax($linkInputName.val()+" : "+$linkInputDesc.val()+" #url "+$linkInputUrl.val())
          # if tlink.name is "" then tlink.name = "link"
          # console.log $linkInputName.val()+" : "+$linkInputDesc.val()+" #url "+$linkInputUrl.val()
        )
        $linkInputName.val('')
        $linkInputUrl.val('')
        $linkInputDesc.val('')
        # $linkInput.blur()
        $linkWrapper.hide()
        $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">Click a Node to select the target.</span>')

      $linkWrapper.hide()

      $linkHolder.focus () =>
        $linkWrapper.show()
        $linkInputName.focus()
        $linkHolder.hide()

      @graphView.on "enter:node:click", (clickedNode) =>
        if @buildingLink
          @tempLink.target = clickedNode
          link = @tempLink
          @dataController.linkAdd(link, (linkres)=> 
            newLink = linkres
            allNodes = @graphModel.getNodes()
            newLink.source = n for n in allNodes when n['_id'] is link.source['_id']
            newLink.target = n for n in allNodes when n['_id'] is link.target['_id']
            @graphModel.putLink(newLink)
            )
          @buildingLink = false
          $('#toplink-instructions').replaceWith('<span id="toplink-instructions"></span>')
          $linkHolder.show()

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
