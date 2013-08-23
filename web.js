require('coffee-script');

var url = process.env.NEO4J_URL || 'http://localhost:7474';
var neo4js = require('neo4js');

var graphDb = new neo4js.GraphDatabase4Node(url);

var App = require('./myapp');

app = new App(graphDb);
