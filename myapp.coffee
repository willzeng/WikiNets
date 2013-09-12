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


    indexPromise = graphDb.index.createNodeIndex "myIndex"
    indexPromise.then((index)->
        app.get '/', (request, response)->
          index.query("name:*").then((nodes)->
              response.render 'index.jade', nodes:nodes
          )

        app.post '/', (request, response)->
          name = request.body.name
          node = graphDb.node {name:name}

          index.index(node, "name", name).then(()->
              response.redirect "/"
          )
    )

    trim = (string)->
      parseInt(string.match(/[0-9]*$/))

    app.get('/json', (request, response)->
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Query Executed"
          console.log noderes.data[0]
          nodedata=(ntmp[0]["data"] for ntmp in noderes.data)
          graphDb.cypher.execute("start n=rel(*) return n;").then(
            (arrres)->
              console.log "Query Executed"
              console.log arrres.data[0]
              arrdata=({source:trim(ntmp[0]["start"]),target:trim(ntmp[0]["end"])} for ntmp in arrres.data)
              response.render 'tester.jade', displaydata:[nodes:nodedata,links:arrdata][0]
          )
      )
    )



    port = process.env.PORT || 3000
    app.listen port, -> console.log("Listening on " + port)
