#!/bin/sh

# compile the coffeescript files in this example project
coffee --watch --compile static/*.coffee &

# compile the coffeescript files in celestrium
coffee --watch --compile -o static/core/ static/core-coffee/ &

# statically serve files out of ./www/
node web.js