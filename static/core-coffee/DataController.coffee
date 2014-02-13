# you should extend this class to create your own data controller
define [], () ->

  class DataController

    init: (instances) ->
      @graphModel = instances["GraphModel"]

    #should add a node to the database
    nodeAdd: (node) ->
      throw "must implement nodeAdd for your data controller"

    #should delete a node from the database
    nodeDelete: (node) ->
      throw "must implement nodeDelete for your data controller"

    #should edit oldNode into newNode
    nodeEdit: (oldNode, newNode) ->
      throw "must implement nodeEdit for your data controller"

    #should add a link to the database
    linkAdd: (link) ->
      throw "must implement linkAdd for your data controller"

    #should delete a link from the database
    linkDelete: (link) ->
      throw "must implement linkDelete for your data controller"

    #should edit oldLink into newLink
    linkEdit: (oldLink, newLink) ->
      throw "must implement linkEdit for your data controller"

    # makes an ajax request to url with data and calls callback with response
    ajax: (url, data, callback) ->
      $.ajax
        url: url
        data: data
        success: callback
