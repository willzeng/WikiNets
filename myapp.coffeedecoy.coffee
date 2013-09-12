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

    app.get('/', (request,response)->
      graphDb.cypher.execute("start n=node(*) return n;").then(
        (noderes)->
          console.log "Query Executed"
          console.log noderes.data[0]
          nodeids=(trim(num[0]["self"]) for num in noderes.data).splice(1)
          `var nodeconvert = {};
          for (i = 0; i < nodeids.length-1; i++) {
            nodeconvert[nodeids[i]+'']=i;            
          }`
          nodedata=(ntmp[0]["data"] for ntmp in noderes.data).splice(1)
          graphDb.cypher.execute("start n=rel(*) return n;").then(
            (arrres)->
              console.log "Query Executed"
              console.log arrres.data[0]
              arrdata=({source:nodeconvert[trim(ntmp[0]["start"])],target:nodeconvert[trim(ntmp[0]["end"])]} for ntmp in arrres.data)
              displaydata = [nodes:nodedata,links:arrdata][0]
              `fs = require('fs');
              fs.writeFile('.\\static\\test.json', JSON.stringify(displaydata), function (err) {
                if (err) throw err;
                console.log('.json SAVED!');
              });`
              response.render 'index.jade', nodes:displaydata
                        )
      )
    )
    
    indexPromise = graphDb.index.createNodeIndex "myIndex"
    indexPromise.then((index)->
      app.get '/', (request, response)->
            )
        )

      app.post '/', (request, response)->
        name = request.body.name
        node = graphDb.node {name:name}

        index.index(node, "name", name).then(()->
            updateViz
            response.redirect "/"
        )
    )


    port = process.env.PORT || 3000
    app.listen port, -> console.log("Listening on " + port)
