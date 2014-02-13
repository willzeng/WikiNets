# extends DataController.coffee to work with a Neo4j database
define ["DataController"], (DataController) ->

  class Neo4jDataController extends DataController

    #should add a node to the database
    nodeAdd: (node, callback) ->
      filteredNode = @filterNode(node)
      console.log "filtered: ", filteredNode
      $.post "/create_node", filteredNode, callback

    #should delete a node from the database
    nodeDelete: (node, callback) ->
      $.post "/delete_node", @filterNode(node), callback

    #should delete a node from the database even when there are remaining links
    nodeDeleteFull: (node, callback) ->
      $.post "/delete_node_full", @filterNode(node), callback

    #should edit oldNode into newNode
    # Send this to the server to edit: {nodeid: selected_node, properties: nodeObject[1], remove: deleted_props}
    nodeEdit: (oldNode, newNode, callback) ->
      oldNode = @filterNode(oldNode)
      #console.log "oldnode: ", oldNode, "and newNode", newNode

      #check which properties have changed and which ones are being deleted
      deleted_props = []
      for property,value of oldNode 
        if newNode[property]?
          if oldNode[property] == newNode[property] #don't have to re-set property value if it hasn't changed
            delete newNode[property]
        else
          #this is a list of properties that are being deleted
          deleted_props.push property

      # ask for confirmation before deleting properties
      # (two different messages in the interest of grammar)
      if (((deleted_props.length is 1) and (!(confirm("Are you sure you want to delete the following property? " + deleted_props)))) || ((deleted_props.length > 1) && (!(confirm("Are you sure you want to delete the following properties? " + deleted_props)))))
        alert "Cancelled saving of node " + oldNode['_id'] + "." 
        return false

      $.post '/edit_node', {nodeid: oldNode['_id'], properties: newNode, remove: deleted_props}, (data) ->
        if data == "error"
          alert "Failed to save changes to node " + oldNode['_id'] + "."
        else
          alert("Saved changes to node " + oldNode['_id'] + ".")
          callback(data)

    #should add a link to the database
    linkAdd: (link, callback) ->
      filteredLink = link
      filteredLink.source = @filterNode(link.source)
      filteredLink.target = @filterNode(link.target)
      $.post "/create_link", link, callback

    #should delete a link from the database
    linkDelete: (link, callback) ->
      $.post "/delete_link", link, callback

    #should edit oldLink into newLink
    linkEdit:  (oldLink, newLink, callback) ->
      oldLink = @filterLink(oldLink)
      #console.log "oldLink: ", oldLink, "and newLink: ", newLink

      #check which properties have changed and which ones are being deleted
      deleted_props = []
      for property,value of oldLink 
        if newLink[property]?
          if oldLink[property] == newLink[property] #don't have to re-set property value if it hasn't changed
            delete newLink[property]
        else
          #this is a list of properties that are being deleted
          deleted_props.push property

      # ask for confirmation before deleting properties
      # (two different messages in the interest of grammar)
      if (((deleted_props.length is 1) and (!(confirm("Are you sure you want to delete the following property? " + deleted_props)))) || ((deleted_props.length > 1) && (!(confirm("Are you sure you want to delete the following properties? " + deleted_props)))))
        alert "Cancelled saving of link " + oldLink['_id'] + "." 
        return false

      $.post '/edit_link', {id: oldLink['_id'], properties: newLink, remove: deleted_props}, (data) ->
        if data == "error"
          alert "Failed to save changes to link " + oldLink['_id'] + "."
        else
          alert("Saved changes to link " + oldLink['_id'] + ".")
          callback(data)


    #filters out the d3 properties added to nodes
    filterNode: (node) ->
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight", "text"]
      filteredNode = {}
      _.each node, (value, property) ->
        filteredNode[property] = value if blacklist.indexOf(property) < 0
      filteredNode

    #filters out the d3 properties added to links
    filterLink: (link) ->
      blacklist = ["_type", "end", "selected", "source", "start", "strength", "target"]
      filteredLink = {}
      _.each link, (value, property) ->
        filteredLink[property] = value if blacklist.indexOf(property) < 0
      filteredLink

    # checks whether property names will break the cypher queries or are any of
    # the reserved terms
    is_illegal: (property, type) ->
      reserved_keys = ["_id", "text", "_type", "Last_Edit_Date", "Creation_Date"]
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

