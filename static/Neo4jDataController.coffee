# extends DataController.coffee to work with a Neo4j database
define ["DataController"], (DataController) ->

  class Neo4jDataController extends DataController

    #should add a node to the database
    nodeAdd: (node, callback) ->
      $.post "/create_node", node, callback

    #should delete a node from the database
    nodeDelete: (node, callback) ->
      $.post "/delete_node", node, callback

    #should edit oldNode into newNode
    nodeEdit: (oldNode, newNode) ->
      $.post "/edit_node", node, callback

    #should add a link to the database
    linkAdd: (link, callback) ->
      $.post "/create_arrow", node, callback

    #should delete a link from the database
    linkDelete: (link) ->
      $.post "/delete_arrow", node, callback

    #should edit oldLink into newLink
    linkEdit: (oldLink, newLink) ->
      $.post "/edit_arrow", node, callback