#!/bin/sh

# compile the coffeescript files in this example project
coffee --watch --compile static/*.coffee &

# compile the coffeescript files in celestrium
coffee --watch --compile -o static/celestrium_code/core/ static/celestrium_code/core-coffee/ 