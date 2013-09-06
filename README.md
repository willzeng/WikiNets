Simple App combining node.js and neo4js
=======================================


Requirements
------------

- npm

        curl http://npmjs.org/install.sh | sh

- heroku

        gem install heroku

- nodejs

        port install nodejs

Try it out
----------

1. clone this repo to your hard-disk

        $ git clone https://github.com/tbaum/heroku-node-neo4js.git
        Cloning into 'heroku-node-neo4js'...
        remote: Counting objects: 8, done.
        remote: Compressing objects: 100% (6/6), done.
        remote: Total 8 (delta 0), reused 8 (delta 0)
        Unpacking objects: 100% (8/8), done.

        $ cd heroku-node-neo4js

2. create a heroku app

        $ heroku create --stack cedar --buildpack https://github.com/tbaum/heroku-buildpack-nodejs.git
        Creating deep-spring-6619... done, stack is cedar
        http://deep-spring-6619.herokuapp.com/ | git@heroku.com:deep-spring-6619.git
        Git remote heroku added

3. add neo4j graph-database

        $ heroku addons:add neo4j
        -----> Adding neo4j to deep-spring-6619... done, v4 (free)

4. start your app
    
        $ git push heroku master
        Counting objects: 8, done.
        Delta compression using up to 2 threads.
        Compressing objects: 100% (6/6), done.
        Writing objects: 100% (8/8), 1.32 KiB, done.
        Total 8 (delta 0), reused 0 (delta 0)

        -----> Heroku receiving push
        -----> Fetching custom buildpack... done
        -----> Node.js app detected
        -----> Fetching Node.js binaries
        -----> Vendoring node 0.6.1
        -----> Installing dependencies with npm 1.0.105
               coffee-script@1.2.0 ./node_modules/coffee-script
               neo4js@0.0.2 ./node_modules/neo4js
               └── underscore@1.2.3
               jade@0.20.0 ./node_modules/jade
               ├── mkdirp@0.2.1
               └── commander@0.2.1
               express@2.5.2 ./node_modules/express
               ├── mkdirp@0.0.7
               ├── qs@0.4.0
               ├── mime@1.2.4
               └── connect@1.8.5
               Dependencies installed
        -----> Discovering process types
               Procfile declares types -> web
        -----> Compiled slug size is 7.7MB
        -----> Launching... done, v6
               http://deep-spring-6619.herokuapp.com deployed to Heroku

        To git@heroku.com:deep-spring-6619.git
         * [new branch]      master -> master

5. done!


Local Testing
-------------

- download, extract and start neo4j (seperate window)

        $ curl -O http://dist.neo4j.org/neo4j-community-1.6.M02-unix.tar.gz
        $ tar xfz neo4j-community-1.6.M02-unix.tar.gz
        $ cd neo4j-community-1.6.M02
        $ ./bin/neo4j console
        Starting Neo4j Server console-mode...
        29.12.11 16:06:58 org.neo4j.server.NeoServerWithEmbeddedWebServer INFO: Starting Neo Server on port [7474] with [20] threads available
        29.12.11 16:06:58 org.neo4j.server.database.Database INFO: Using database at /Users/tbaum/neo4j-community-1.6.M02/data/graph.db
        29.12.11 16:06:58 org.neo4j.server.modules.DiscoveryModule INFO: Mounted discovery module at [/]
        29.12.11 16:06:58 org.neo4j.server.plugins.PluginManager INFO: Loaded server plugin "CypherPlugin"
        29.12.11 16:06:58 org.neo4j.server.plugins.PluginManager INFO: Loaded server plugin "GremlinPlugin"
        29.12.11 16:06:58 org.neo4j.server.modules.RESTApiModule INFO: Mounted REST API at [/db/data/]
        29.12.11 16:06:58 org.neo4j.server.modules.ManagementApiModule INFO: Mounted management API at [/db/manage/]
        29.12.11 16:06:59 org.neo4j.server.modules.WebAdminModule INFO: Mounted webadmin at [/webadmin]
        29.12.11 16:06:59 org.neo4j.server.web.Jetty6WebServer INFO: Mounting static content at [/webadmin] from [webadmin-html]
        29.12.11 16:07:00 org.neo4j.server.statistic.StatisticStartupListener INFO: adding statistic-filter to /webadmin
        29.12.11 16:07:00 org.neo4j.server.statistic.StatisticStartupListener INFO: adding statistic-filter to /db/manage
        29.12.11 16:07:00 org.neo4j.server.statistic.StatisticStartupListener INFO: adding statistic-filter to /db/data
        29.12.11 16:07:00 org.neo4j.server.statistic.StatisticStartupListener INFO: adding statistic-filter to /
        29.12.11 16:07:00 org.neo4j.server.NeoServerWithEmbeddedWebServer INFO: Server started on [http://localhost:7474/]

- prepare npm-dependencies

        $ npm install
        coffee-script@1.2.0 ./node_modules/coffee-script
        jade@0.20.0 ./node_modules/jade
        ├── commander@0.2.1
        └── mkdirp@0.2.1
        neo4js@0.0.2 ./node_modules/neo4js
        └── underscore@1.2.3
        express@2.5.2 ./node_modules/express
        ├── mime@1.2.4
        ├── mkdirp@0.0.7
        ├── qs@0.4.0
        └── connect@1.8.5

- start local node

        $ node web.js
        Listening on 3000
