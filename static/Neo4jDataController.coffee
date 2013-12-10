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

    #should edit oldNode into newNode
    nodeEdit: (oldNode, newNode) ->
      $.post "/edit_node", @filterNode(node), callback

    #should add a link to the database
    linkAdd: (link, callback) ->
      $.post "/create_arrow", link, callback

    #should delete a link from the database
    linkDelete: (link) ->
      $.post "/delete_arrow", link, callback

    #should edit oldLink into newLink
    linkEdit: (oldLink, newLink) ->
      $.post "/edit_arrow", link, callback

    #filters out the d3 properties added to nodes
    filterNode: (node) ->
      blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
      filteredNode = {}
      _.each node, (value, property) ->
        filteredNode[property] = value if blacklist.indexOf(property) < 0
      filteredNode

