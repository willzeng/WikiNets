express = require 'express'

module.exports = class MyApp

  constructor:(@graphDb)->
    graphDb = @graphDb

    app = express.createServer express.logger()

    app.configure ->
      app.set 'views', __dirname + '/public'
      app.set 'view options', layout:false
      app.use express.methodOverride()
      app.use express.bodyParser()
      app.use app.router
      app.use express.static(__dirname+'/static')

    app.get('/', (request,response)->
      response.render('index.jade')
    )

    ###  Responds with a JSON formatted for D3JS viz of the entire Neo4j database ###
    # Not currently used, but should be updated to include link information
    # to be useful for exporting
    app.get('/json',(request,response)->
      inputer = (builder)->response.json builder
      getvizjson inputer, request, response
    )

    ### Responds with a list of all the nodes ###
    app.get('/get_nodes', (request,response)->
      console.log "get_nodes Query Requested"
      cypherQuery = "start n=node(*) return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          console.log "get_nodes Lookup Executed"
          nodeList = (addID(n[0].data,trim(n[0].self)[0]) for n in noderes.data)
          response.json nodeList
      )
    )

    ### Responds with a list of all the nodes 
        that have the shouldLoad attribute as true
    ###
    app.get('/get_default_nodes', (request,response)->
      console.log "get_default_nodes Query Requested"
      cypherQuery = "start n=node(*) where n.shouldLoad=\"true\" return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          console.log "get_default_nodes Lookup Executed"
          nodeList = (addID(n[0].data,trim(n[0].self)[0]) for n in noderes.data)
          response.json nodeList
      )
    )

    ### Creates a node using a Cypher query ###
    app.post('/create_node', (request, response) ->
      console.log "Node Creation Requested"
      cypherQuery = "create (n"
      #console.log request.body
      if JSON.stringify(request.body) isnt '{}'
        cypherQuery += " {"
        for property, value of request.body
          cypherQuery += "#{property}:'#{value}', "
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-2) + "}"
      cypherQuery += ") return n;"
      console.log "Executing " + cypherQuery
      ###
      Problem: this does not allow properties to have spaces in them,
      e.g. "firstname: 'Will'" works but "first name: 'Will'" does not
      It seems like this problem could be avoided if Neo4js supported
      parameters in Cypher, but it does not, as far as I can see.
      ###
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          console.log "query"
          nodeIDstart = noderes.data[0][0]["self"].lastIndexOf('/') + 1
          nodeID = noderes.data[0][0]["self"].slice(nodeIDstart)
          console.log "Node Creation Done, ID = " + nodeID
          newNode = noderes.data[0][0]["data"]
          newNode['_id'] = nodeID
          console.log "newNode: ", newNode
          response.send newNode
      )
    )

    ### Creates a link using a Cypher query ###
    # request should be of the form {properties: {name:type , key1:val1 ...}, source: sourceNode, target: targeNode}
    app.post('/create_link', (request, response) ->
      console.log "Link Creation Requested"
      sourceNode = request.body.source
      targetNode = request.body.target
      console.log "sourceNode", sourceNode
      console.log "targetNode", targetNode
      cypherQuery = "start n=node(" + sourceNode['_id'] + "), m=node(" + targetNode['_id'] + ") create (n)-[r: link"
      if request.body.properties isnt undefined
        cypherQuery += " {"
        for property, value of request.body.properties
          cypherQuery += "#{property}:'#{value}', "
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-2) + "}"
      cypherQuery +="]->(m) return r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (relres) ->
          #console.log "res Data", relres.data[0][0]
          relIDstart = relres.data[0][0]["self"].lastIndexOf('/') + 1
          newRelID = relres.data[0][0]["self"].slice(relIDstart)
          newLink = relres.data[0][0]["data"]
          newLink['_id'] = newRelID
          newLink.source = sourceNode
          newLink.start = sourceNode['_id']
          newLink.target = targetNode
          newLink.end = targetNode['_id']
          newLink.strength = 1
          console.log "here is the new link", newLink
          response.send newLink
        (relres) ->
          console.log relres
          response.send "error"
      )
    )

    ###
    Gets a node by ID
    Request is of the form {nodeid: 9}
    ###
    app.post('/get_node_by_id', (request,response)->
      console.log "Node Data Requested"
      cypherQuery = "start n=node(" + request.body.nodeid + ") return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          console.log "Node ID Lookup Executed"
          response.json noderes.data[0][0]["data"]
        (noderes) ->
          console.log "Node not found"
          response.send "error"
      )
    )

    ###
    get a link by id, request be of the form {id: 1}
    ###
    app.post('/get_link_by_id', (request,response)->
      console.log "Link Data Requested"
      cypherQuery = "start r=rel(" + request.body.id + ") return r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (relres) ->
          console.log "Link ID Lookup Executed"
          console.log relres.data[0][0]
          response.json {from: trim(relres.data[0][0]["start"])[0], to: trim(relres.data[0][0]["end"])[0], type:relres.data[0][0]["type"], properties: relres.data[0][0]["data"]}
        (relres) ->
          console.log "Link not found"
          response.send "error"
      )
    )

    ### Edits a node using a Cypher query ###
    # Request is of the form {nodeid: 0, properties: {}, remove: []} where remove is a list of
    # the properties to be deleted
    app.post('/edit_node', (request, response) ->
      console.log "Node Edit Requested"
      cypherQuery = "start n=node(" + request.body.nodeid + ") "
      if request.body.properties isnt undefined
        cypherQuery += "set n."
        for property, value of request.body.properties
          cypherQuery += "#{property}='#{value}', n."
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-4)
      if request.body.remove isnt undefined
        cypherQuery += " remove n."
        for property in request.body.remove
          cypherQuery += "#{property}, n."
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-4)
      cypherQuery += " return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          nodeIDstart = noderes.data[0][0]["self"].lastIndexOf('/') + 1
          nodeID = noderes.data[0][0]["self"].slice(nodeIDstart)
          console.log "Node Edit Done, ID = " + nodeID
          savedNode = noderes.data[0][0]["data"]
          savedNode['_id'] = nodeID
          console.log "savedNode: ", savedNode
          response.json savedNode
        (noderes) ->
          console.log "Node Edit Failed"
          response.send "error"
      )
    )

    ### Edits a link using a Cypher query ###
    # Request is of the form {nodeid: 0, properties: {}, remove: []} where remove is a list of
    # the properties to be deleted
    app.post('/edit_link', (request, response) ->
      console.log "Link Edit Requested"
      cypherQuery = "start r=rel(" + request.body.id + ") "
      if request.body.properties isnt undefined
        cypherQuery += "set r."
        for property, value of request.body.properties
          cypherQuery += "#{property}='#{value}', r."
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-4)
      if request.body.remove isnt undefined
        cypherQuery += " remove r."
        for property in request.body.remove
          cypherQuery += "#{property}, r."
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-4)
      cypherQuery += " return r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          nodeIDstart = noderes.data[0][0]["self"].lastIndexOf('/') + 1
          nodeID = noderes.data[0][0]["self"].slice(nodeIDstart)
          console.log "Link Edit Done, ID = " + nodeID
          response.json noderes.data[0][0]["data"]
        (noderes) ->
          console.log "Link Edit Failed"
          response.send "error"
      )
    )


    ###
    Deletes a node 
    ###
    app.post('/delete_node', (request,response)->
      console.log "Node Deletion Requested"
      cypherQuery = "start n=node(" + request.body['_id'] + ") delete n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          console.log "Node Deleted"
          response.send "success"
        (noderes) ->
          console.log "Could Not Delete Node"
          response.send "error"
      )
    )


    ###
    Deletes a node AND ALL LINKS TO IT
    ###
    app.post('/delete_node_full', (request,response)->
      console.log "Node Deletion Requested"
      cypherQuery = "start n=node("+ request.body['_id'] + ") match (n)-[r]-(m) delete r"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) -> 
          console.log "Links Deleted"
          cypherQuery = "start n=node(" + request.body['_id'] + ") delete n;"
          console.log "Executing " + cypherQuery
          graphDb.cypher.execute(cypherQuery).then(
            (noderes) ->
              console.log "Links and Node Deleted"
              response.send "success"
          )
        ) 
    )


    ###
    Deletes a link 
    ###
    app.post('/delete_link', (request,response)->
      console.log "Link Deletion Requested"
      cypherQuery = "start r=rel(" + request.body['_id'] + ") delete r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          console.log "Link Deleted"
          response.send "success"
        (noderes) ->
          console.log "Could Not Delete Link"
          response.send "error"
      )
    )


    # Returns a list of all the names in the databse
    # not currently in use
    app.get('/node_names', (request,response)->
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Query Executed"
          nodesNamesAndIds = ({name:n[0]['data']['name'], _id:trim(n[0]["self"])[0]} for n in noderes.data)
          #nodesNamesAndIds = (n[0]['data']['name'] for n in noderes.data)
          response.json nodesNamesAndIds
          )
    )

    # gets a list of all node properties occuring in the database
    # used in VisualSearch
    # for each of those properties, it also gets a list of all values, though that should be moved to a separate query
    # Request may be empty
    app.get('/get_all_node_keys', (request,response)->
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Get All Node Keys: Query Executed"
          nodeData = (n[0].data for n in noderes.data)
          keys = []
          ((keys.push key for key,value of n when not (key in keys)) for n in nodeData)
          response.json keys.sort()
          )
    )

    # Gets a list of all values occuring in the database for a given node property
    # and returns them as an alphabetically sorted list for VisualSearch
    # Request should be of form {property: 'foo'}
    # if value is very long it is shortened - cf. shorten()
    # TO DO: add a limit to number of results for large databases
    app.post('/get_all_key_values', (request,response)->
      cypherQuery = "start n=node(*) where has(n." + request.body.property + ") return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          console.log "Get All Key values: Query Executed"
          nodeData = (n[0].data for n in noderes.data)
          values = ['(any)']
          # the option '(any)' will allow searching for any node with a certain property,
          # independent of value - cf. /search_nodes
          (values.push shorten(n[request.body.property]) for n in nodeData when not (shorten(n[request.body.property]) in values))
          response.json values.sort()
          )
    )

    # Returns all nodes matching the property-value pairs given in the request body
    # this is for VisualSearch
    # Request should be of form {property1: 'value1', property2: 'value2', ...}
    app.post('/search_nodes', (request,response)->
      console.log "Searching nodes"
      cypherQuery = "start n=node(*) where "
      if JSON.stringify(request.body) isnt '{}'
        for property, value of request.body
          if value is '(any)'
            # this allows searching for any node that has a certain property, independent of value
            cypherQuery += "has(n.#{property}) and "
          else if value.substr(-3) is '...'
            # this means value has been shortened, cf. shorten()
            # in this case use regular expression in query to compensate
            cypherQuery += "n.#{property} =~ '#{value.slice(0,-2)}*' and "
          else
            cypherQuery += "n.#{property} = '#{value}' and "
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-4)
      cypherQuery += "return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          nodeList = (addID(n[0].data,trim(n[0].self)[0]) for n in noderes.data)
          response.json nodeList
          )
    )

    # Request is of the form {node: node, nodes:{node0, node1, ...}}
    # returns all of the links between node and any of the nodes
    # TO DO: send only node IDs rather than full nodes in request
    app.post('/get_links', (request,response)->
      console.log "GET LINKS REQUESTED"
      node= request.body.node
      nodes= request.body.nodes

      if !(nodes?) then response.send "error"

      nodeIndexes = (k["_id"] for k in nodes)

      cypherQuery = "START n=node("+node["_id"]+"), m=node("+nodeIndexes+") MATCH p=(n)-[]-(m) RETURN relationships(p);"

      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (relres) ->
          console.log "Get Links executed"
          #console.log trim(link[0][0].self)[0]

          allSpokes = (addStrength(link[0][0].data, trim(link[0][0].start)[0], trim(link[0][0].end)[0], trim(link[0][0].self)[0], link[0][0].type) for link in relres.data)

          getLink = (nID) -> 
            spoke for spoke in allSpokes when spoke.start is nID or spoke.end is nID

          relList = ((if (getLink(n)[0]?) then getLink(n)[0] else {strength:0}) for n in nodeIndexes)
          response.json relList

        (relres) ->
          console.log "Node not found"
          response.send "error"
      )
    )


    # Request is an array of nodes
    # Returns an array of all the nodes linked to any one of them
    app.post('/get_linked_nodes', (request,response)->
      
      console.log "GET LINKED NODES REQUESTED"
      nodes= request.body.nodes
      console.log "NODES: ", nodes

      nodeIndexes = (n["_id"] for n in nodes when n["_id"] isnt undefined)

      cypherQuery = "START n=node("+nodeIndexes+") MATCH p=(n)-[]-(m) RETURN m;"

      console.log cypherQuery

      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (nodeRes) ->
          console.log "Get Linked Nodes executed"

          nodeList = (addID(node[0].data,trim(node[0].self)) for node in nodeRes.data)
          response.json nodeList
          
        (nodeRes) ->
          console.log "Node not found"
          response.send "error"
      )
    )


    #Request is of the form {checkKeys: [key0, key1,...], query:"queryStr"}
    #Does returns all the nodes that have a key which contains the query 
    #or have a value of a key in checkKeys that contains the query
    app.post '/node_index_search', (request, response)->
      theKeys = request.body.checkKeys
      query = request.body.query
      condition = "where "
      condition+="n.#{key}=~\".*#{query}.*\" OR " for key in theKeys
      condition+="False"
      cypherQuery = "start n=node(*) #{condition} return n;"

      #do a fulltext search of all the values of keys in checkKeys for all nodes
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          console.log "Node Index Search: Query Executed"
          nodeData = (addID(n[0].data,trim(n[0].self)[0]) for n in noderes.data)

          #check which of the keys themselves match the query
          regexpression = ".*#{query}.*"
          pattern = new RegExp(regexpression)          
          matchedKeys = (key for key in theKeys when key.match(pattern)?)

          #if some keys match the search query 
          #then find which nodes have those keys
          if matchedKeys.length > 0
            keyscondition = "where "
            keyscondition += "has(n.#{key}) OR " for key in matchedKeys
            keyscondition += "False"
            cypherQuery = "start n=node(*) #{keyscondition} return n;"
            console.log "Executing " + cypherQuery
            graphDb.cypher.execute(cypherQuery).then(
              (matchedKeys)->
                nodeDataKeys = (addID(n[0].data,trim(n[0].self)[0]) for n in matchedKeys.data)
                #return nodes with matched values and matched keys
                response.json nodeData.concat nodeDataKeys
              )
          else
            #only return nodes with matched keys
            response.json nodeData
      )


    #Tells the server where to listen
    port = process.env.PORT || 3000
    app.listen port, -> console.log("Listening on " + port)

    #HELPER METHODS ===============================================

    # adds a default strength value to a relationship 
    # TODO: (should only do this if there isnt one already)
    addStrength = (dict,start,end,id, type) -> 
      dict['strength'] = 1
      dict['start'] = start
      dict['end'] = end
      dict['_id'] = id+"" #make sure that the added id is a string
      dict['_type'] = type
      dict

    #Trims a url i.e. 'http://localhost:7474/db/data/node/312' -> 312
    trim = (string)->
      string.match(/[0-9]*$/)

    #Shortens a string to the first maxLength-3 characters, replacing the rest with "..."
    # if it is longer than maxLength characters
    shorten = (string) ->
      maxLength = 30
      if string.length > maxLength
        string.substring(0,maxLength-3) + "..."
      else
        string

    # adds an id to a node
    addID = (dict, id) -> 
      dict['_id'] = id+"" #make sure that the added id is a string
      dict

    ### makes queries of database to build a JSON formatted for D3JS viz of the entire Neo4j database
      that is stored in the displaydata variable.
    ###
    getvizjson = (callback, request, response)->
      console.log "making getvizjson"
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Query Executed"           
          # Extract the ID's off all the nodes.  These are then reindexed for the d3js viz format.
          nodeids=(trim(num[0]["self"]) for num in noderes.data)
          ### Generate reindexing array ###
          `var nodeconvert = {};
          for (i = 0; i < nodeids.length; i++) {
            nodeconvert[nodeids[i]+'']=i;            
          }`
          # Get all the data for all the nodes, i.e. all the properties and values, e.g
          nodedata=(ntmp[0]["data"] for ntmp in noderes.data)
          `for (i=0; i < nodeids.length; i++) {
             nodedata[i]["_id"] = nodeids[i]+'';
          }`
          graphDb.cypher.execute("start n=rel(*) return n;").then(
            (arrres)->
              console.log "Query Executed"
              arrdata=({source:nodeconvert[trim(ntmp[0]["start"])],target:nodeconvert[trim(ntmp[0]["end"])]} for ntmp in arrres.data)
              displaydata = [nodes:nodedata,links:arrdata][0]

              callback displaydata
          )
      )


