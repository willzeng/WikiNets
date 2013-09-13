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
          We also ignore the root node of database. E.g.
            self: 'http://localhost:7474/db/data/node/312'
          ###
          nodeids=(trim(num[0]["self"]) for num in noderes.data).splice(1)

          ### Generate reindexing array ###
          `var nodeconvert = {};
          for (i = 0; i < nodeids.length-1; i++) {
            nodeconvert[nodeids[i]+'']=i;            
          }`

          ### Get all the data for all the nodes, i.e. all the properties and values, e.g
            data: { propertyExample: 'valueExample' }
          ###
          nodedata=(ntmp[0]["data"] for ntmp in noderes.data).splice(1)
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


    ###  Respondes with a JSON formatted for D3JS viz of the entire Neo4j database ###
    app.get('/json',(request,response)->
      inputer = (builder)->response.json builder
      getvizjson inputer, request, response
    )

    ### Original index thingy:
    indexPromise = graphDb.index.createNodeIndex "myIndex"
    indexPromise.then((index)->
      app.post '/', (request, response)->
        name = request.body.name
        node = graphDb.node {name:name}

        index.index(node, "name", name).then(()->
            response.redirect "/"
        )
    )
    ###


    indexPromise = graphDb.index.createNodeIndex "myIndex"
    indexPromise.then((index)->
      app.post '/create_node', (request, response)->
        node = graphDb.node request.body
        console.log "Node Created"

        index.index(node, "name", request.body.name).then(()->
          console.log "Index updated with node " + request.body.name + "\n\nRedirecting..."
          response.redirect "/"
        )
    )


    port = process.env.PORT || 3000
    app.listen port, -> console.log("Listening on " + port)
