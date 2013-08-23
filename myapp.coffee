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
    port = process.env.PORT || 3000
    app.listen port, -> console.log("Listening on " + port)
