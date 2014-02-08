# provides details and editing functionality for the selected links
define [], () ->

  class LinkEdit extends Backbone.View

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
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Link Edit', true

      @Create = instances['local/Create']

      @nodeEdit = instances['local/NodeEdit']

    update: ->
      @$el.empty()
      selectedLinks = @selection.getSelectedLinks()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["selected", "source", "target", "strength", "_type"]
      # not sure whether "strength" should be in the blacklist or not...?
      _.each selectedLinks, (link) =>
        console.log link
        $linkDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        header = @findHeader(link)
        $("<div class=\"node-profile-title\">#{header}</div>").appendTo $linkDiv
        _.each link, (value, property) =>
          value += ""
          if blacklist.indexOf(property) < 0
            if (property == "start" and @graphView.findText(link.source))
              makeLinks = value + " \"" + @graphView.findText(link.source) + "\""          
            else if (property == "end" and @graphView.findText(link.target)) 
              makeLinks = value + " \"" + @graphView.findText(link.target) + "\""
            else if value?
              makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi,"<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>")
            else
              makeLinks = value
            $("<div class=\"node-profile-property\">#{property}: #{makeLinks}</div>").appendTo $linkDiv
        

        $linkEdit = $("<input id=\"LinkEditButton#{link['_id']}\" class=\"LinkEditButton\" type=\"button\" value=\"Edit this link\">").appendTo $linkDiv
        $linkEdit.click(() =>
          @editLink(link, $linkDiv, blacklist)
          )

    editLink: (link, linkDiv, blacklist) =>
          console.log "Editing link: " + link['_id']
          linkInputNumber = 0
          linkDiv.html("<div class=\"node-profile-title\">Editing #{@findHeader(link)}</div><form id=\"Link#{link['_id']}EditForm\"></form>")
          _.each link, (value, property) ->
            if blacklist.indexOf(property) < 0 and ["_id", "Last_Edit_Date", "Creation_Date", "start", "end"].indexOf(property) <0
              newEditingFields = """
                <div id=\"Link#{link['_id']}EditDiv#{linkInputNumber}\" class=\"Link#{link['_id']}EditDiv\">
                  <input style=\"width:80px\" id=\"Link#{link['_id']}EditProperty#{linkInputNumber}\" value=\"#{property}\" class=\"propertyLink#{link['_id']}Edit\"/> 
                  <input style=\"width:80px\" id=\"Link#{link['_id']}EditValue#{linkInputNumber}\" value=\"#{value}\" class=\"valueLink#{link['_id']}Edit\"/> 
                  <input type=\"button\" id=\"removeLink#{link['_id']}Edit#{linkInputNumber}\" value=\"x\" onclick=\"this.parentNode.parentNode.removeChild(this.parentNode);\">
                </div>
              """
              $(newEditingFields).appendTo("#Link#{link['_id']}EditForm")
              linkInputNumber = linkInputNumber + 1

          $linkMoreFields = $("<input id=\"moreLink#{link['_id']}EditFields\" type=\"button\" value=\"+\">").appendTo(linkDiv)
          $linkMoreFields.click(() =>
            @nodeEdit.addField(linkInputNumber, "Link#{link['_id']}Edit")
            linkInputNumber = linkInputNumber+1
          )


          $linkSave = $("<input name=\"LinkSaveButton\" type=\"button\" value=\"Save\">").appendTo(linkDiv)
          $linkSave.click () => 
            newLinkObj = @nodeEdit.assign_properties("Link#{link['_id']}Edit")
            if newLinkObj[0]
              newLink = newLinkObj[1]
              newLink['_id'] = link['_id']
              @dataController.linkEdit(link, newLink, (savedLink) =>
                savedLink['_id'] = link['_id']
                savedLink['_type'] = link['_type']
                savedLink['start'] = link['start']
                savedLink['end'] = link['end']
                savedLink['source'] = link['source']
                savedLink['target'] = link['target']
                savedLink['strength'] = link['strength']
                #console.log savedLink    
                @graphModel.filterLinks (link) ->
                  not (savedLink['_id'] == link['_id'])
                @graphModel.putLink(savedLink)
                @selection.toggleSelection(savedLink)
              )

          $linkDelete = $("<input name=\"LinkDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(linkDiv)
          $linkDelete.click () => 
            if confirm("Are you sure you want to delete this link?") then @deleteLink(link, () => @selection.toggleSelection(link))

          $linkCancel =  $("<input name=\"LinkCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(linkDiv)
          $linkCancel.click () => @cancelEditing(link, linkDiv, blacklist)

    cancelEditing: (link, linkDiv, blacklist) =>
      linkDiv.html("<div class=\"node-profile-title\">#{@findHeader(link)}</div>")
      _.each link, (value, property) ->
        $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo linkDiv  if blacklist.indexOf(property) < 0
      $linkEdit = $("<input id=\"LinkEditButton#{link['_id']}\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this link\">").appendTo linkDiv
      $linkEdit.click(() =>
        @editLink(link, linkDiv, blacklist)
        )


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
      if @graphView.findText(link.source) and @graphView.findText(link.target)
        "(" + @graphView.findText(link.source) + ") - " + link._type + " - (" + @graphView.findText(link.target) + ")"
      else if @graphView.findText(link.source)
        "(" + @graphView.findText(link.source) + ") - " + link._type + " - (" + link.end + ")"
      else if @graphView.findText(link.target)
        "(" + link.start + ") - " + link._type + " - (" + @graphView.findText(link.target) + ")"
      else
        "(" + link.start + ") - " + link._type + " - (" + link.end + ")"

