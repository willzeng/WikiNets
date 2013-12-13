# provides details of the selected nodes
define [], () ->

  class NodeEdit extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @selection = instances["NodeSelection"]
      @selection.on "change", @update.bind(this)
      @listenTo instances["KeyListener"], "down:80", () => @$el.toggle()
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Node Edit'
      @$el.toggle()

      #require plugins
      @Create = instances['local/Create']

    update: ->
      @$el.empty()
      selectedNodes = @selection.getSelectedNodes()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
      _.each selectedNodes, (node) =>
        $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        $("<div class=\"node-profile-title\">#{node['text']}</div>").appendTo $nodeDiv
        _.each node, (value, property) ->
          $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0
        $nodeEdit = $("<input id=\"NodeEditButton#{node['_id']}\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this node\">").appendTo $nodeDiv
        $nodeEdit.click(() =>
          @editNode(node, $nodeDiv, blacklist)
          )
          
          
    ## most of this is not working yet
    editNode: (node, nodeDiv, blacklist) ->
          console.log "Editing node: " + node['_id']
          nodeInputNumber = 0
          
          nodeDiv.html("<div class=\"node-profile-title\">Editing #{node['text']} (id: #{node['_id']})</div><form id=\"Node#{node['_id']}EditForm\"></form>")
          _.each node, (value, property) ->
            if blacklist.indexOf(property) < 0 and ["_id", "text"].indexOf(property) < 0
              $("<div id=\"Node#{node['_id']}EditDiv#{nodeInputNumber}\" class=\"Node#{node['_id']}EditDiv\"><input style=\"width:80px\" id=\"Node#{node['_id']}EditProperty#{nodeInputNumber}\" value=\"#{property}\" /> <input style=\"width:80px\" id=\"Node#{node['_id']}EditValue#{nodeInputNumber}\" value=\"#{value}\" /> <input type=\"button\" id=\"removeNode#{node['_id']}Edit#{nodeInputNumber}\" value=\"x\" onclick=\"this.parentNode.parentNode.removeChild(this.parentNode);\"></div>").appendTo("#Node#{node['_id']}EditForm")
              nodeInputNumber = nodeInputNumber + 1
          
          $nodeMoreFields = $("<input id=\"moreNode#{node['_id']}EditFields\" type=\"button\" value=\"+\">").appendTo(nodeDiv)
          $nodeMoreFields.click(() =>
            @Create.addField(nodeInputNumber, "Node#{node['_id']}Edit")
            nodeInputNumber = nodeInputNumber+1
            )
            
          $nodeCreate = $("<input name=\"NodeCreateButton\" type=\"button\" value=\"Save\">").appendTo(nodeDiv)
          $nodeCreate.click(() -> console.log "Save Node requested")

          $nodeDelete = $("<input name=\"NodeDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(nodeDiv)
          $nodeDelete.click(() -> console.log "Deletion requested")

          $nodeCancel =  $("<input name=\"NodeCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(nodeDiv)
          $nodeCancel.click(() =>
            nodeDiv.html("<div class=\"node-profile-title\">#{node['text']}</div>")
            _.each node, (value, property) ->
              $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo nodeDiv  if blacklist.indexOf(property) < 0
            $nodeEdit = $("<input id=\"NodeEditButton#{node['_id']}\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this node\">").appendTo nodeDiv
            $nodeEdit.click(() =>
              @editNode(node, nodeDiv, blacklist)
              )
            )
