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

    app.get('/test', (request,response)->
      response.render('test.jade')
    )

    ###  Responds with a JSON formatted for D3JS viz of the entire Neo4j database ###
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
      cypherQuery = "start n=node(" + sourceNode['_id'] + "), m=node(" + targetNode['_id'] + ") create (n)-[r:" + request.body.properties.name
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

    ### Creates a relationship using a Cypher query ###
    # request should be of the form {properties: {key1:val1 , ...}, from: node_id, to: node_id, type: type}
    app.post('/create_rel', (request, response) ->
      console.log "Relationship Creation Requested"
      cypherQuery = "start n=node(" + request.body.from + "), m=node(" + request.body.to + ") create (n)-[r:" + request.body.type
      if request.body.properties isnt undefined
        cypherQuery += " {"
        for property, value of request.body.properties
          cypherQuery += "#{property}:'#{value}', "
        cypherQuery = cypherQuery.substring(0,cypherQuery.length-2) + "}"
      cypherQuery +="]->(m) return r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (relres) ->
          console.log relres.data[0][0]
          relIDstart = relres.data[0][0]["self"].lastIndexOf('/') + 1
          response.send relres.data[0][0]["self"].slice(relIDstart)
        (relres) ->
          console.log relres
          response.send "error"
      )
    )


    ###
    Collects data from a node so it can be edited  
    ###
    app.post('/get_id', (request,response)->
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

    ### Edits a node using a Cypher query ###
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
    Collects data from an arrow so it can be edited  
    ###
    app.post('/get_arrow', (request,response)->
      console.log "Arrow Data Requested"
      cypherQuery = "start r=rel(" + request.body.id + ") return r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (relres) ->
          console.log "Arrow ID Lookup Executed"
          console.log relres.data[0][0]
          response.json {from: trim(relres.data[0][0]["start"])[0], to: trim(relres.data[0][0]["end"])[0], type:relres.data[0][0]["type"], properties: relres.data[0][0]["data"]}
        (relres) ->
          console.log "Arrow not found"
          response.send "error"
      )
    )

    ### Edits a link using a Cypher query ###
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
    # for each of those properties, it also gets a list of all values, though that should be moved to a separate query
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

    # gets a list of all values occuring in the database for a given node property
    # and returns them as an alphabetically sorted list
    # - will have to add a limit to number of results for large databases
    # - should also add a cutoff for very long value strings
    app.post('/get_all_key_values', (request,response)->
      cypherQuery = "start n=node(*) where has(n." + request.body.property + ") return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          console.log "Get All Key values: Query Executed"
          nodeData = (n[0].data for n in noderes.data)
          values = ['(any)']
          (values.push shorten(n[request.body.property]) for n in nodeData when not (shorten(n[request.body.property]) in values))
          response.json values.sort()
          )
    )

    # returns all nodes matching the property-value pairs given in the request body
    app.post('/search_nodes', (request,response)->
      console.log "Searching nodes"
      cypherQuery = "start n=node(*) where "
      if JSON.stringify(request.body) isnt '{}'
        for property, value of request.body
          if value is '(any)'
            cypherQuery += "has(n.#{property}) and "
          else if value.substr(-3) is '...'
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

    # adds a default strength value to a relationship 
    # TODO: (should only do this if there isnt one already)
    addStrength = (dict,start,end,id, type) -> 
      dict['strength'] = 1
      dict['start'] = start
      dict['end'] = end
      dict['_id'] = id+"" #make sure that the added id is a string
      dict['_type'] = type
      dict

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


    # - getLinkedNodes(nodes, callback) should call callback with
    #   an array of the union of the linked nodes of each node in nodes.
    #   currently, a node can have any attributes you like so they long
    #   as they don't conflict with d3's attributes and they
    #   must have a "text" attribute.
    app.post('/get_linked_nodes', (request,response)->
      
      console.log "GET LINKED NODES REQUESTED"
      #console.log request
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

    port = process.env.PORT || 3000
    app.listen port, -> console.log("Listening on " + port)

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
