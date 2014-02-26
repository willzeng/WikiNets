# provides details and editing functionality for the selected links
define [], () ->

  class LinkEdit extends Backbone.View

    # colors = ["darkgray", "aqua", "black", "blue", "darkblue", "fuchsia", "green", "darkgreen", "lime", "maroon", "navy", "olive", "orange", "purple", "red", "silver", "teal", "yellow"]
    # hexColors = ["#A9A9A9","#00FFFF","#000000","#0000FF", "#00008B","#FF00FF","#008000","#006400","#00FF00","#800000","#000080","#808000","#FFA500","#800080","#FF0000","#C0C0C0","#008080","#FFFF00"]
    colors = ['#F56545', '#FFBB22', '#BBE535', '#77DDBB', '#66CCDD', '#A9A9A9']

    constructor: (@options) ->
      super()

    init: (instances) ->
      
      #require plugins
      @dataController = instances['local/Neo4jDataController']

      @graphModel = instances['GraphModel']
      @graphModel.on "change", @update.bind(this)

      @graphView = instances['GraphView']

      @selection = instances["LinkSelection"]
      @selection.on "change", @update.bind(this)
      @listenTo instances["KeyListener"], "down:16:80", () => @$el.toggle()
      #instances["Layout"].addPlugin @el, @options.pluginOrder, 'Link Edit', true
      $(@el).appendTo $('#omniBox')

      @Create = instances['local/Create']

      @nodeEdit = instances['local/NodeEdit']

    update: ->
      @$el.empty()
      selectedLinks = @selection.getSelectedLinks()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["selected", "source", "target", "strength", "_type", "_id"]
      # not sure whether "strength" should be in the blacklist or not...?
      _.each selectedLinks, (link) =>
        if !(link.color?) then link.color="#A9A9A9"
        else if !(link.color.toUpperCase() in colors) then link.color="#A9A9A9"
        $linkDiv = $("<div class=\"node-profile\"/>").css("background-color","#{link.color}").appendTo($container)
        @renderProfile(link, $linkDiv, blacklist)
        

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

    cancelEditing: (link, linkDiv, blacklist) =>
      linkDiv.empty()
      @renderProfile(link, linkDiv, blacklist)



    deleteLink: (delLink, callback)=>
      @dataController.linkDelete delLink, (response) =>
        if response == "error"
          alert "Could not delete Link."
        else
          console.log "Link Deleted"
          @graphModel.filterLinks (link) ->
            !(delLink['_id'] == link['_id'])
          callback()

    findHeader: (link) =>
      headerName = link.name
      if link.url?
        realurl = ""
        result = link.url.search(new RegExp(/^http:\/\//i));
        if !result
          realurl = link.url
        else
          realurl = 'http://'+link.url;
        headerName = '<a href='+realurl+' target="_blank">'+link.name+'</a>'
      if @graphView.findText(link.source) and @graphView.findText(link.target)
        "(#{@graphView.findText(link.source)})-#{headerName}-(#{@graphView.findText(link.target)})"
      else if @graphView.findText(link.source)
        "(#{@graphView.findText(link.source)})-#{headerName}-(#{link.end})"
      else if @graphView.findText(link.target)
        "(#{link.start})-#{headerName}-(#{@graphView.findText(link.target)})"
      else
        "(#{link.start})-#{headerName}-(#{link.end})"

    renderProfile: (link, linkDiv, blacklist) =>
      header = @findHeader(link)
      $linkHeader = $("<div class=\"node-profile-title\">#{header}</div>").appendTo linkDiv
      $linkEdit = $("<i class=\"fa fa-pencil-square-o\"></i>").prependTo $linkHeader

      $linkDeselect = $("<i class=\"right fa fa-times\"></i>").appendTo $linkHeader
      $linkDeselect.click () => @selection.toggleSelection(link)

      _.each link, (value, property) =>
        value += ""
        if blacklist.indexOf(property) < 0
          if (property == "start" and @graphView.findText(link.source))
            makeLinks = value + " \"" + @graphView.findText(link.source) + "\""          
          else if (property == "end" and @graphView.findText(link.target)) 
            makeLinks = value + " \"" + @graphView.findText(link.target) + "\""
          else if property == "_Last_Edit_Date" or property == "_Creation_Date"
            makeLinks = value.substring(4,21)
          else if value?
            makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi,"<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>")
          else
            makeLinks = value
          if property != "color"
            $("<div class=\"node-profile-property\">#{property}: #{makeLinks}</div>").appendTo linkDiv
      

      $linkEdit.click(() =>
        @editLink(link, linkDiv, blacklist)
        )
