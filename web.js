require('coffee-script');

var url = 'http://localhost:7474';
//var url = 'http://wikinets-edge:wiKnj2gYeYOlzWPUcKYb@wikinetsedge.sb01.stations.graphenedb.com:24789';
//var url = 'http://wikinets-demo:BEmJ3fqsO02bHl9xay7X@wikinetsdemo.sb01.stations.graphenedb.com:24789';

//sosi
//var url = 'http://wikinets-sosi:yKenjgdUuhYXpcjevdNk@wikinetssosi.sb01.stations.graphenedb.com:24789';
//pims
//var url = 'http://wikinets-pims:GH9I6tXib6Zl9K5RmQBR@wikinetspims.sb01.stations.graphenedb.com:24789';


var neo4js = require('neo4js');

var graphDb = new neo4js.GraphDatabase4Node(url);

var App = require('./wikinets');

app = new App(graphDb);

