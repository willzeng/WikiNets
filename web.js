require('coffee-script');

//var url = process.env.NEO4J_URL || 'http://localhost:7474';
//var url = 'http://wikinets-edge:wiKnj2gYeYOlzWPUcKYb@wikinetsedge.sb01.stations.graphenedb.com:24789';
var url = 'http://wikinets-shoebox:ofzn7wT7CrrrSDLkXrog@http://wikinetsshoebox.sb01.stations.graphenedb.com:24789';

var neo4js = require('neo4js');

var graphDb = new neo4js.GraphDatabase4Node(url);

var App = require('./wikinets');

app = new App(graphDb);

