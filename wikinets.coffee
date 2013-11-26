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


    trim = (string)->
      string.match(/[0-9]*$/)

    # adds an id to a node
    addID = (dict, id) -> 
      dict['_id'] = id
      dict

    ### makes queries of database to build a JSON formatted for D3JS viz of the entire Neo4j database
      that is stored in the displaydata variable.  Method then runs argument onSuccess(displaydata)
    ###
    getvizjson = (onSuccess, request, response)->
      console.log "making getvizjson"
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Query Executed"

          ### Display an example of what is returned by the database for each node. E.g.

          { outgoing_relationships: 'http://localhost:7474/db/data/node/312/relationships/out',
            labels: 'http://localhost:7474/db/data/node/312/labels',
            data: { propertyExample: 'valueExample' },
            all_typed_relationships: 'http://localhost:7474/db/data/node/312/relationships/all/{-list|&|types}',
            traverse: 'http://localhost:7474/db/data/node/312/traverse/{returnType}',
            self: 'http://localhost:7474/db/data/node/312',
            property: 'http://localhost:7474/db/data/node/312/properties/{key}',
            outgoing_typed_relationships: 'http://localhost:7474/db/data/node/312/relationships/out/{-list|&|types}',
            properties: 'http://localhost:7474/db/data/node/312/properties',
            incoming_relationships: 'http://localhost:7474/db/data/node/312/relationships/in',
            extensions: {},
            create_relationship: 'http://localhost:7474/db/data/node/312/relationships',
            paged_traverse: 'http://localhost:7474/db/data/node/312/paged/traverse/{returnType}{?pageSize,leaseTime}'
            all_relationships: 'http://localhost:7474/db/data/node/312/relationships/all',
            incoming_typed_relationships: 'http://localhost:7474/db/data/node/312/relationships/in/{-list|&|types}' }  

          ###
          console.log noderes.data[0]
           
          ### Extract the ID's off all the nodes.  These are then reindexed for the d3js viz format.
          E.g.
            self: 'http://localhost:7474/db/data/node/312'
          ###
          nodeids=(trim(num[0]["self"]) for num in noderes.data)

          ### Generate reindexing array ###
          `var nodeconvert = {};
          for (i = 0; i < nodeids.length; i++) {
            nodeconvert[nodeids[i]+'']=i;            
          }`

          ### Get all the data for all the nodes, i.e. all the properties and values, e.g
            data: { propertyExample: 'valueExample' }
          ###
          nodedata=(ntmp[0]["data"] for ntmp in noderes.data)
          `for (i=0; i < nodeids.length; i++) {
             nodedata[i]["_id"] = nodeids[i]+'';
          }`
          graphDb.cypher.execute("start n=rel(*) return n;").then(
            (arrres)->
              console.log "Query Executed"

              ### Display an example of what is returned by the database for each arrow. E.g.

              { start: 'http://localhost:7474/db/data/node/314',
                data: {},
                self: 'http://localhost:7474/db/data/relationshi
                property: 'http://localhost:7474/db/data/relatio
                properties: 'http://localhost:7474/db/data/relat
                type: 'RELATED_TO',
                extensions: {},
                end: 'http://localhost:7474/db/data/node/316' }

              ###
              console.log arrres.data[0]
              arrdata=({source:nodeconvert[trim(ntmp[0]["start"])],target:nodeconvert[trim(ntmp[0]["end"])]} for ntmp in arrres.data)
              displaydata = [nodes:nodedata,links:arrdata][0]
              
              ###  Code to write the full database data to a file.  Currently inactive. ###
              ###
              `fs = require('fs');
              fs.writeFile('.\\static\\test.json', JSON.stringify(displaydata), function (err) {
                if (err) throw err;
                console.log('.json SAVED!');
              });`
              ###

              ### Render the index.jade and pass it the displaydata, which is a
              JSON formatted for D3JS viz of the entire Neo4j database ###
              onSuccess(displaydata)
          )
      )

    app.get('/', (request,response)->
      inputer = (builder)->response.render('index.jade', displaydata:builder)
      getvizjson inputer, request, response
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

    ###  Post function to test lookup by Node id that will return the value of the property 
      "Info", which will eventually go in the Infobox.  
    ###
    app.post('/search_id', (request,response)->
      console.log "Search Query Requested"
      searchid = request.body.nodeid
      cypherQuery = "start n=node("+searchid+") return n;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes)->
          console.log "Node ID Lookup Executed"
          selectedINFO=noderes.data[0][0]["data"]
          response.json selectedINFO["Info"]
      )
    )

    ### Creates a node using a Cypher query ###
    app.post('/create_node', (request, response) ->
      console.log "Node Creation Requested"
      cypherQuery = "create (n"
      console.log request.body
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
          nodeIDstart = noderes.data[0][0]["self"].lastIndexOf('/') + 1
          nodeID = noderes.data[0][0]["self"].slice(nodeIDstart)
          console.log "Node Creation Done, ID = " + nodeID
          response.send nodeID
      )
    )

    ### Creates a relationship using a Cypher query ###
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
          response.json noderes.data[0][0]["data"]
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
      cypherQuery = "start n=node(" + request.body.nodeid + ") delete n;"
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

    ### Edits an arrow using a Cypher query ###
    app.post('/edit_arrow', (request, response) ->
      console.log "Arrow Edit Requested"
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
          console.log "Arrow Edit Done, ID = " + nodeID
          response.json noderes.data[0][0]["data"]
        (noderes) ->
          console.log "Arrow Edit Failed"
          response.send "error"
      )
    )


    ###
    Deletes an arrow 
    ###
    app.post('/delete_arrow', (request,response)->
      console.log "Arrow Deletion Requested"
      cypherQuery = "start r=rel(" + request.body.id + ") delete r;"
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (noderes) ->
          console.log "Arrow Deleted"
          response.send "success"
        (noderes) ->
          console.log "Could Not Delete Arrow"
          response.send "error"
      )
    )

    ###
    Parses a syntax markup query to create a node
    ###
    app.post('/submit', (request,response)->
      console.log "Textin Query Requested"
      console.log request.body
      console.log request.body.text

      ###Parse the input query into key value pairs###
      strsplit=request.body.text.split("#");
      strsplit[0]=strsplit[0].replace(/:/," #description ");### The : is shorthand for #description ###
      text=strsplit.join("#")

      pattern = new RegExp(/#([a-zA-Z0-9]+) ([^#]+)/g)
      dict = {}
      match = {}
      dict[match[1].trim()]=match[2].trim() while match = pattern.exec(text)

      console.log "This is the dictionary", dict

      ###The first entry becomes the name###
      dict["name"]=text.split("#")[0].trim()
      console.log "This is the title", text.split("#")[0].trim()
      console.log dict

      console.log "Node Creation Requested"
      cypherQuery = "create (n"
      console.log dict
      if JSON.stringify(dict) isnt '{}'
        cypherQuery += " {"
        for property, value of dict
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
          nodeIDstart = noderes.data[0][0]["self"].lastIndexOf('/') + 1
          nodeID = noderes.data[0][0]["self"].slice(nodeIDstart)
          console.log "Node Creation Done, ID = " + nodeID
          response.send nodeID
      )
    )

    ###
    Parses a syntax markup query to create an arrow
    ###
    app.post('/submitarrow', (request,response)->
      console.log "Arrow create query Requested"
      console.log request.body
      console.log request.body.text

      ###Parse the input query into key value pairs###
      strsplit=request.body.text.split("#");
      strsplit[0]=strsplit[0].replace(/:/," #description ");### The : is shorthand for #description ###
      text=strsplit.join("#")

      pattern = new RegExp(/#([a-zA-Z0-9]+) ([^#]+)/g)
      dict = {}
      match = {}
      dict[match[1].trim()]=match[2].trim() while match = pattern.exec(text)

      console.log "This is the dictionary", dict

      ###The first entry becomes the arrow's type###
      console.log "This is the arrow type", text.split("#")[0].trim()
      if text.split("#")[0].trim() is ''
        dict["type"]="none";
      else
        dict["type"]=text.split("#")[0].trim()
      console.log "This is the arrow type", dict["type"]
      console.log dict

      console.log "Relationship Creation Requested"
      cypherQuery = "start n=node(" + request.body.from + "), m=node(" + request.body.to + ") create (n)-[r:" + dict.type
      if dict isnt undefined
        cypherQuery += " {"
        for property, value of dict
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

    app.get('/node_names', (request,response)->
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Query Executed"
          nodesNamesAndIds = ({name:n[0]['data']['name'], _id:trim(n[0]["self"])[0]} for n in noderes.data)
          #nodesNamesAndIds = (n[0]['data']['name'] for n in noderes.data)
          response.json nodesNamesAndIds
          )
    )

    ###
    get_node_names returns a list of all the node names
    ###
    app.get('/get_node_names', (request,response)->
      inputer = (builder)->response.json (node['name'] for node in builder["nodes"] when typeof node['name'] isnt "undefined")
      getvizjson inputer, request, response
    )

    # adds a default strength value to a relationship 
    # TODO: (should only do this if there isnt one already)
    addStrength = (dict,start,end) -> 
      dict['strength'] = 1
      dict['start'] = start
      dict['end'] = end
      dict

    app.post('/get_links', (request,response)->
      console.log "GET LINKS REQUESTED"
      node= request.body.node
      nodes= request.body.nodes

      nodeIndexes = (k["_id"] for k in nodes)

      cypherQuery = "START n=node("+node["_id"]+"), m=node("+nodeIndexes+") MATCH p=(n)-[]-(m) RETURN relationships(p);"

      console.log cypherQuery
      console.log "Executing " + cypherQuery
      graphDb.cypher.execute(cypherQuery).then(
        (relres) ->
          console.log "Get Links executed"

          allSpokes = (addStrength(link[0][0].data, trim(link[0][0].start)[0],trim(link[0][0].end)[0]) for link in relres.data)

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
      console.log request
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
