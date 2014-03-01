# provides details of the selected items
define [], () ->

  class SelectedDetails extends Backbone.View

    @colors = colors = ['#F56545', '#FFBB22', '#BBE535', '#77DDBB', '#66CCDD', '#A9A9A9']
    #these are they peoperties that are not shown in the profile
    @nodeBlacklist = @blacklist = blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight", "_id", "color","shouldLoad"]

    constructor: (@options) ->
      super()

    init: (instances) ->
      
      #require plugins
      @dataController = instances['local/Neo4jDataController']

      @graphModel = instances['GraphModel']
      @graphModel.on "change", @update.bind(this)

      @graphView = instances['GraphView']

      @selection = instances["NodeSelection"]
      @selection.on "change", if !@buildingLink then @update.bind(this)

      @linkSelection = instances["LinkSelection"]
      @linkSelection.on "change", if !@buildingLink then @update.bind(this)

      #the p key toggles this plugin on and off
      @listenTo instances["KeyListener"], "down:80", () => @$el.toggle()
      
      #place the plugin in the omniBox
      $(@el).appendTo $('#omniBox')

    update: ->
      @$el.empty()

      #create profiles based on selectedNodes
      selectedNodes = @selection.getSelectedNodes()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      _.each selectedNodes, (node) =>
        node = validateNode(node)
        $nodeDiv = $("<div class=\"node-profile\"/>").css("background-color","#{node.color}").appendTo($container)
        @renderProfile(node, $nodeDiv, 4) 

    #This validates a node's data to make sure it matches the requirements for display with
    #this plugin
    validateNode: (node) ->
      if !(node.color?) then node.color="#A9A9A9"
      else if !(node.color.toUpperCase() in colors) then node.color="#A9A9A9"
      node

    #This profile is rendered for nodes whenever they are selected.
    #Outputs: relevant properties, values, an editting button, and a deselection button
    renderProfile: (node, nodeDiv, propNumber) =>
      nodeDiv.empty()
      header = @findHeader(node)
      
      $nodeHeader = $("<div class=\"node-profile-title\">#{header}</div>").appendTo nodeDiv

      $nodeEdit = $("<i class=\"fa fa-pencil-square \"></i>").css("margin","6px").appendTo $nodeHeader
      $nodeEdit.click () =>
        @editNode(node, nodeDiv, @nodeBlacklist)

      $nodeDeselect = $("<i class=\"right fa fa-times\"></i>").css("margin","1px").appendTo $nodeHeader
      $nodeDeselect.click () => @selection.toggleSelection(node)

      whitelist = ["description", "url"]

      #limits number of displayed properties to propNumber (default: propNumber=4)
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

      if propNumber < nodeLength
        $showMore = $("<div class='showMore'><a href='#'>Show More...</a></div>").appendTo nodeDiv 
        $showMore.click () =>
          @renderProfile(node, nodeDiv, blacklist, propNumber+10)
          
      #Adds button that creates link from selected node to user-inputted node
      @addLinker node, nodeDiv

      #Adds the links from this node to its neighbors
      initialSpokeNumber = 5
      $spokeHolder = $("<div class='spokeHolder'></div>").appendTo nodeDiv.parent()
      @addSpokes node, $spokeHolder, initialSpokeNumber

    editNode: (node, nodeDiv, blacklist) ->
          console.log "Editing node: " + node['_id']
          nodeInputNumber = 0

          #TODO these color settings should probably go in a settings plugin
          origColor = "#A9A9A9" #TODO: map this to the CSS file color choice for node color
                    
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
              if value.toUpperCase() in colors
                origColor = value


          colorEditingField = '
            <form action="#" method="post">
                <div class="controlset">Color<input id="color'+node['_id']+'" name="color'+node['_id']+'" type="text" value="'+origColor+'"/></div>
            </form>
          '
          $(colorEditingField).appendTo(nodeDiv)
          $("#color#{node['_id']}").colorPicker {showHexField: false}

          #Adds a checkbox to determine if the node should be loaded initially
          if node.shouldLoad? then shouldLoad = node.shouldLoad else shouldLoad = false
          $loaderHolder = $('<span> Load by default <br> </span>').css("font-size","12px").appendTo nodeDiv
          $loaderToggle = $('<input type="checkbox" id=\"shouldLoad'+node._id+'\">')
            .attr("checked", shouldLoad)
            .prependTo $loaderHolder 

          $nodeMoreFields = $("<input id=\"moreNode#{node['_id']}EditFields\" type=\"button\" value=\"+\">").appendTo(nodeDiv)
          $nodeMoreFields.click(() =>
            @addField(nodeInputNumber, "Node#{node['_id']}Edit")
            nodeInputNumber = nodeInputNumber+1
          )

          $nodeSave = $("<input name=\"nodeSaveButton\" type=\"button\" value=\"Save\">").appendTo(nodeDiv)
          $nodeSave.click () => 
            newNodeObj = @assign_properties("Node#{node['_id']}Edit")
            if newNodeObj[0]
              $.post "/get_node_by_id", {'nodeid': node['_id']}, (data) =>
                if data['_Last_Edit_Date'] == node['_Last_Edit_Date'] or confirm("Node " + @findHeader(node) + " (id: #{node['_id']}) has changed on server. Are you sure you want to risk overwriting the changes?")
                  # possibly list all changes?
                  newNode = newNodeObj[1]
                  newNode['color'] = $("#color"+node['_id']).val()
                  newNode['_id'] = node['_id']
                  newNode['_Creation_Date'] = node['_Creation_Date']
                  newNode["shouldLoad"] = $("#shouldLoad#{node._id}").prop('checked')
                  @dataController.nodeEdit(node,newNode, (savedNode) =>           
                    @graphModel.filterNodes (node) ->
                      !(savedNode['_id'] == node['_id'])
                    @graphModel.putNode(savedNode)
                    @selection.toggleSelection(savedNode)
                    @cancelEditing(savedNode, nodeDiv, blacklist)
                  )
                else
                  alert("Did not save node " + @findHeader(node) + " (id: #{node['_id']}).")


          $nodeDelete = $("<input name=\"NodeDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(nodeDiv)
          $nodeDelete.click () => 
            if confirm("Are you sure you want to delete this node?") then @deleteNode(node, () => @selection.toggleSelection(node))

          $nodeCancel =  $("<input name=\"NodeCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(nodeDiv)
          $nodeCancel.click () => @cancelEditing(node, nodeDiv, blacklist)

    editLink: (link, linkDiv, blacklist) =>
          console.log "Editing link: " + link['_id']
          origColor = "#A9A9A9" #TODO: map this to the CSS file color choice for node color
          linkInputNumber = 0
          linkDiv.html("<div class=\"node-profile-title\">Editing #{@findHeader(link)}</div><form id=\"Link#{link['_id']}EditForm\"></form>")
          _.each link, (value, property) ->
            if blacklist.indexOf(property) < 0 and ["_id", "_Last_Edit_Date", "_Creation_Date", "start", "end", "color"].indexOf(property) <0
              newEditingFields = """
                <div id=\"Link#{link['_id']}EditDiv#{linkInputNumber}\" class=\"Link#{link['_id']}EditDiv\">
                  <input style=\"width:80px\" id=\"Link#{link['_id']}EditProperty#{linkInputNumber}\" value=\"#{property}\" class=\"propertyLink#{link['_id']}Edit\"/> 
                  <input style=\"width:80px\" id=\"Link#{link['_id']}EditValue#{linkInputNumber}\" value=\"#{value}\" class=\"valueLink#{link['_id']}Edit\"/> 
                  <input type=\"button\" id=\"removeLink#{link['_id']}Edit#{linkInputNumber}\" value=\"x\" onclick=\"this.parentNode.parentNode.removeChild(this.parentNode);\">
                </div>
              """
              $(newEditingFields).appendTo("#Link#{link['_id']}EditForm")
              linkInputNumber = linkInputNumber + 1
            else if property == "color"
              origColor=value
              # if value in colors 
              #   origColor = hexColors[colors.indexOf(value)]
              # else if origColor in hexColors 
              #   origColor = value


          colorEditingField = '
            <form action="#" method="post">
                <div class="controlset">Color<input id="color'+link['_id']+'" name="color'+link['_id']+'" type="text" value="'+origColor+'"/></div>
            </form>
          '
          $(colorEditingField).appendTo(linkDiv)

          $("#color#{link['_id']}").colorPicker {showHexField: false} 

          $linkMoreFields = $("<input id=\"moreLink#{link['_id']}EditFields\" type=\"button\" value=\"+\">").appendTo(linkDiv)
          $linkMoreFields.click(() =>
            @nodeEdit.addField(linkInputNumber, "Link#{link['_id']}Edit")
            linkInputNumber = linkInputNumber+1
          )


          $linkSave = $("<input name=\"LinkSaveButton\" type=\"button\" value=\"Save\">").appendTo(linkDiv)
          $linkSave.click () => 
            newLinkObj = @nodeEdit.assign_properties("Link#{link['_id']}Edit")
            if newLinkObj[0]
              $.post "/get_link_by_id", {'id': link['_id']}, (data) =>
                if data['properties']['_Last_Edit_Date'] == link['_Last_Edit_Date'] or confirm("Link " + @findHeader(link) + " (id: #{link['_id']}) has changed on server. Are you sure you want to risk overwriting the changes?")
                  # possibly list all changes?
                  newLink = newLinkObj[1]
                  newLink['_id'] = link['_id']
                  newLink['color'] = $("#color"+link['_id']).val()
                  newLink['_Creation_Date'] = link['_Creation_Date']
                  @dataController.linkEdit(link, newLink, (savedLink) =>
                    savedLink['_id'] = link['_id']
                    savedLink['_type'] = link['_type']
                    savedLink['start'] = link['start']
                    savedLink['end'] = link['end']
                    savedLink['source'] = link['source']
                    savedLink['target'] = link['target']
                    savedLink['strength'] = link['strength']
                    savedLink['_Creation_Date'] = link['_Creation_Date']
                    #console.log savedLink    
                    @graphModel.filterLinks (link) ->
                      not (savedLink['_id'] == link['_id'])
                    @graphModel.putLink(savedLink)
                    @selection.toggleSelection(savedLink)
                    @cancelEditing(link, linkDiv, blacklist)
                  )
                else
                  alert("Did not save link " + @findHeader(link) + " (id: #{link['_id']}).")

          $linkDelete = $("<input name=\"LinkDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(linkDiv)
          $linkDelete.click () => 
            if confirm("Are you sure you want to delete this link?") then @deleteLink(link, () => @selection.toggleSelection(link))

          $linkCancel =  $("<input name=\"LinkCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(linkDiv)
          $linkCancel.click () => @cancelEditing(link, linkDiv, blacklist)

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
    assign_properties: (form_name, is_illegal = @dataController.is_illegal, node) => 
        submitOK = true
        propertyObject = {}
        editDate = new Date()
        propertyObject["_Last_Edit_Date"] = editDate
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
        if node.url?
          realurl = ""
          result = node.url.search(new RegExp(/^http:\/\//i));
          if !result
            realurl = node.url
          else
            realurl = 'http://'+node.url;
          '<a href='+realurl+' target="_blank">'+node.name+'</a>'
        else
          node.name
      else if node.title?
        node.title
      else
        ''

    findLinkHeader: (link) =>
      if !(link.name?) or link.name == "" then headerName = "<i>empty link</i>" else headerName = link.name
      if link.url?
        realurl = ""
        result = link.url.search(new RegExp(/^http:\/\//i));
        if !result
          realurl = link.url
        else
          realurl = 'http://'+link.url;
        headerName = '<a href='+realurl+' target="_blank">'+link.name+'</a>'
      headerName
      # if @graphView.findText(link.source) and @graphView.findText(link.target)
      #   "(#{@graphView.findText(link.source)})-#{headerName}-(#{@graphView.findText(link.target)})"
      # else if @graphView.findText(link.source)
      #   "(#{@graphView.findText(link.source)})-#{headerName}-(#{link.end})"
      # else if @graphView.findText(link.target)
      #   "(#{link.start})-#{headerName}-(#{@graphView.findText(link.target)})"
      # else
      #   "(#{link.start})-#{headerName}-(#{link.end})"

    renderLinkProfile: (link, linkDiv, blacklist, propNumber) =>
      linkDiv.empty()
      header = @findLinkHeader(link)
      
      $linkHeader = $("<div class=\"node-profile-title\">#{header}</div>").appendTo linkDiv

      $linkEdit = $("<i class=\"fa fa-pencil-square \"></i>").css("margin","6px").appendTo $linkHeader
      $linkEdit.click (e) =>
        e.stopPropagation()
        @editNode(node, linkDiv, blacklist)

      $linkDeselect = $("<i class=\"right fa fa-times\"></i>").css("margin","1px").appendTo $linkHeader
      $linkDeselect.click (e) => 
        e.stopPropagation()
        console.log "de"
        @linkSelection.deselectLink(link)

      whitelist = ["description", "url"]

      #limits number of displayed properties to propNumber (default: propNumber=4)
      linkLength = 0
      for p,v of link
        if !(p in blacklist)
          linkLength = linkLength+1

      counter = 0
      _.each link, (value, property) ->
        if counter >= propNumber
          return
        value += ""
        if blacklist.indexOf(property) < 0
          if value?
            makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi,"<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>")
          else
            makeLinks = value
          if property in whitelist
            $("<div class=\"node-profile-property\">#{makeLinks}</div>").appendTo linkDiv 
          else if property == "_Last_Edit_Date" or property=="_Creation_Date"
            $("<div class=\"node-profile-property\">#{property}:  #{makeLinks.substring(4,21)}</div>").appendTo linkDiv  
          else
            $("<div class=\"node-profile-property\">#{property}:  #{makeLinks}</div>").appendTo linkDiv
          counter++ 

      if propNumber < linkLength
        $showMore = $("<div class='showMore'><a href='#'>Show More...</a></div>").appendTo linkDiv 
        $showMore.click () =>
          @renderLinkProfile(link, linkDiv, blacklist, propNumber+10)

    addLinker: (node, nodeDiv) =>
      @tempLink = {}

      nodeID = node['_id']

      linkSideID = "id=" + "'linkside" + nodeID + "'"
      $linkSide = $('<div ' + linkSideID + '><hr style="margin:3px"></div>').appendTo nodeDiv
      
      holderClassName = "'profilelinkHolder" + nodeID + "'"
      className = "class=" + holderClassName
      $linkHolder = $('<input type="button"' + className + 'value="Add Link"></input><br>')
        .css("width",100)
        .css("margin-left",85)
        .appendTo $linkSide

      linkWrapperDivID = "id=" + "'source-container" + nodeID + "'"
      $linkWrapper = $('<div ' + linkWrapperDivID + ' class="linkWrapperClass">').appendTo $linkSide
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

      $(document).on "click", ()->
        $linkWrapper.hide()
        $linkHolder.show()
      $linkWrapper.on "click", (e)->
        e.stopPropagation()

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


    addSpokes: (node, spokeHolder, maxSpokes) =>
      spokeHolder.empty()
      nHash = @graphModel.get("nodeHash")
      lHash = @graphModel.get("linkHash")
      spokesID = "spokesDiv#{nHash(node)}"
      $spokesDiv = $('<div id='+spokesID+'>').appendTo spokeHolder
      spokes = (link for link in @graphModel.getLinks() when nHash(link.source) is nHash(node) or nHash(link.target) is nHash(node))

      if spokes.length > 0
        spoke_counter = 0
        for spoke in spokes
          if spoke_counter >= maxSpokes then break else spoke_counter++
          savedSpoke = spoke
          displayName = @findLinkHeader(spoke)
          if !(spoke.color?) then spoke.color = "#A9A9A9"
          $spokeDiv = $('<div class="spokeDiv">'+displayName+' </div>')
            .css("border","2px solid #{spoke.color}")
            .appendTo $spokesDiv

          $spokeSource = $('<span class="nodeNameBox">'+spoke.source.name+'</span>')
            .css("background-color","#{spoke.source.color}")
            .prependTo $spokeDiv
          $spokeSource.on "click", (e) =>
            e.stopPropagation()
            clickedLink = $(e.target).parent().data("link")[0]
            @selection.selectNode(clickedLink.source)

          $spokeTarget = $('<span class="nodeNameBox">'+spoke.target.name+'</span>')
            .css("background-color","#{spoke.target.color}")
            .appendTo $spokeDiv
          $spokeTarget.on "click", (e) =>
            e.stopPropagation()
            clickedLink = $(e.target).parent().data("link")[0]
            @selection.selectNode(clickedLink.target)

          $('<i class="fa fa-caret-right fa-2x"></i> ').prependTo $spokeDiv

          $spokeDiv.data("link", [spoke])
          $spokeDiv.on "click", (e) =>
            clickedLink = $(e.target).data("link")[0]
            @renderLinkProfile(clickedLink, $(e.target), @blacklist, 5)

      if maxSpokes < spokes.length
        $showMoreSpokes = $("<div class=\"showMore\"><a href='#'>Show More...</a></div>").appendTo spokeHolder 
        $showMoreSpokes.on "click", (e) =>
          $('<div id='+spokesID+'>').empty()
          @addSpokes(node, spokeHolder, maxSpokes+4)

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

    # $(document).click(function(envent){

    # });
      # $linkWrapperSlector = $('.linkWrapperClass')
      # console.log $linkWrapperSlector
