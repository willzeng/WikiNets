#!/bin/sh

# compile the coffeescript files in this example project
coffee --compile static/main.coffee &&\
coffee --compile static/WikiNetsDataProvider.coffee &&\
coffee --compile static/Neo4jDataController.coffee &&\

# compile the coffeescript files in celestrium
coffee --compile -o static/celestrium_code/core/ static/celestrium_code/core-coffee/ &&\

# statically serve files out of ./www/
node web.js