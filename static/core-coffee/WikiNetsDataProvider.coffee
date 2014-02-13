###

This is an example extension of a DataProvider.

You should define this to be backed by your own source of data.
This uses a static graph for the sake of example, but typically
you would make ajax requests and call the callbacks once the data
has been received.

DataProvider extensions need only define two functions

- getLinks(node, nodes, callback) should call callback with
  an array, A, of links st. A[i] is the link from node to nodes[i]
  links are javascript objects and can have any attributes you like
  so long as they don't conflict with d3's attributes and they
  must have a "strength" attribute in [0,1]

- getLinkedNodes(nodes, callback) should call callback with
  an array of the union of the linked nodes of each node in nodes.
  currently, a node can have any attributesyou like so they long
  as they don't conflict with d3's attributes and they
  must have a "text" attribute.

DataProviders are integrated to always be called when a node is
added to the graph to ensure the corresponding links between
all nodes in the graph are added.

###

define ["DataProvider"], (DataProvider) ->

  class WikiNetsDataProvider extends DataProvider

    ###

    See above for a spec of this method.
    As a sanity check getLinks({"text": "A"}, [{"text": "B"}], f)
    should call f with [{"strength": 1.0}] as an argument.

    ###
    getLinks: (node, nodes, callback) ->
      #console.log "NODE: ", node
      #console.log "NODES: ", nodes"
      if nodes.length > 0
        $.post "/get_links", {'node': node, 'nodes': nodes}, (data) -> 
          # console.log "NODE: ", node
          # console.log "NODES: ", nodes
          # console.log "THE get_links POST DATA: ", data
          callback data


    ###

    See above for a spec of this method.
    As a sanity check getLinkedNodes([{"text": "C"}], f)
    should call f with [{"text": "B"}] as an argument

    ###
    getLinkedNodes: (nodes, callback) ->

      #TODO MAKE THIS GENERIC
      makeDisplayable = (n) ->  
        n['text'] = n.name
        n

      $.post "/get_linked_nodes", {'nodes': nodes}, (data) -> 
        #console.log "NODES: ", nodes
        #console.log "THE GET LINKED NODES POST DATA: ", data

        celNodes = makeDisplayable(n) for n in data

        callback data


    getEverything: (callback) ->
      $.get('/get_nodes', callback)

