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

    update: ->
      @$el.empty()
      selectedLinks = @selection.getSelectedLinks()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["selected", "source", "target", "strength", "_type"]
      # not sure whether "strength" should be in the blacklist or not...?
      _.each selectedLinks, (link) =>
        $linkDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        header = link._type
        # would be nice to have something of the form (start)-TYPE-(end) as header
        # but not sure how to make it look nice and understandable
        # unless we encourage people to name links so that "start_node_header link_type end_node_header" is grammatical
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

    editLink: (link, linkDiv, blacklist) ->
          console.log "Editing link: " + link['_id']
          linkInputNumber = 0
          header = link._type
          linkDiv.html("<div class=\"node-profile-title\">Editing #{header} (id: #{link['_id']}; start: #{link.start}, end: #{link.end})</div><form id=\"Link#{link['_id']}EditForm\"></form>")
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
            @addField(linkInputNumber, "Link#{link['_id']}Edit")
            linkInputNumber = linkInputNumber+1
          )



    # this is just duplicated from NodeEdit
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
