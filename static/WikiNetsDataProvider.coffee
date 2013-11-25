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

  ###

  Our example graph data.
  graph[node text][othernode text] ::=\
    link strength between node and otherNode

  BUG/TODO: doesn't handle asymmetric weights well.

  ###

  # graph =
  #   "A":
  #     "B": 1.0
  #   "B":
  #     "A": 1.0
  #     "C": 0.1
  #   "C":
  #     "B": 0.1

  # nodesList = {};
  # linksList = {};

  class WikiNetsDataProvider extends DataProvider

    # filterGetName = (name) ->
    #   name = "" if typeof name is "undefined"
    #   return name

    # getName = (id) ->
    #   return filterGetName(node['name']) for node in nodesList when node['_id'] is id

    # getID = (name) ->
    #   #console.log "getID for name: ", name
    #   return node['_id'] for node in nodesList when node['name'] is name

    # assignNeighbors = (centerNode, Nnode, NewGraph, strength) ->
    #   #console.log "add link from: ", centerNode, " to: ", Nnode, " with strength: ", strength
    #   NewGraph[centerNode][Nnode] = strength #Gives the new link a random strength

    # findTargets = (id, NewGraph) ->
    #   #console.log "findTargets called with id: ", id
    #   assignNeighbors(getName(id),getName(link['target']), NewGraph, link['strength']) for link in linksList when link['source'] is id
    #   #console.log "link from: ", getName(link['source']), " to: ", getName(link['target'])
    #   return NewGraph

    # setUpNewGraph = (id,NewGraph) ->
    #   NewGraph[getName(id)]={}

    # findSources = (id, NewGraph) ->
    #   assignNeighbors(getName(id),getName(link['source']), NewGraph, link['strength']) for link in linksList when link['target'] is id
    #   return NewGraph

    # renumberLinkSTIds = (linkSTId) ->
    #   return nodesList[linkSTId]['_id']

    # newLink = (oldlink) ->
    #   tmp = {}
    #   tmp['source'] = renumberLinkSTIds(oldlink['source'])
    #   tmp['target'] = renumberLinkSTIds(oldlink['target'])
    #   tmp['strength'] = 1 #Math.random()*0.9+0.1
    #   return tmp

    # convertForCelestrium = (graphNew) ->
    #   ###console.log "CONVERT HAS BEEN CALLED"
    #   console.log graphNew["nodes"]###
    #   nodesList = (n for n in graphNew["nodes"])
    #   linksList = (newLink(link) for link in graphNew["links"])
    #   NewGraph = {}
    #   ###console.log "NODESLIST", nodesList
    #   console.log "linksList", linksList###
    #   setUpNewGraph(node['_id'],NewGraph) for node in nodesList
    #   findTargets(node['_id'], NewGraph) for node in nodesList 
    #   #console.log "This is the NewGraph after findTargets", NewGraph
    #   findSources(node['_id'], NewGraph) for node in nodesList 
    #   #console.log "This is the NewGraph after findSources", NewGraph
    #   return NewGraph


    ###

    See above for a spec of this method.
    As a sanity check getLinks({"text": "A"}, [{"text": "B"}], f)
    should call f with [{"strength": 1.0}] as an argument.

    ###
    getLinks: (node, nodes, callback) ->
      #console.log "NODE: ", node
      #console.log "NODES: ", nodes

      $.post "/get_links", {'node': node, 'nodes': nodes}, (data) -> 
        console.log "NODE: ", node
        console.log "NODES: ", nodes
        console.log "THE get_links POST DATA: ", data
        callback data

        # $.getJSON "/json", (data) -> 
        #   #console.log "This is the data: ", data



        #   graph = convertForCelestrium(data)
          
        #   #console.log "THIS IS THE GRAPH: ", graph
        #   ###console.log "This is the graph: ", graph###
        #   thing = _.map nodes, (otherNode, i) ->
        #     return "strength": graph[node.text][otherNode.text]
        #   console.log "THE LOG: ", thing

        #   callback _.map nodes, (otherNode, i) ->
        #     return "strength": graph[node.text][otherNode.text]

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
      # $.getJSON "/json", (data) ->
      #   #console.log "This is the data: ", data
        
      #   graph = convertForCelestrium(data)

      #   #console.log "getLinkedNodes called with: ", nodes

      #   callback _.chain(nodes)
      #     .map (node) ->
      #       _.map graph[node.text], (strength, text) ->
      #         "text": text
      #         "_id": getID(text)
      #     .flatten()
      #     .value()