#!/bin/sh

# compile the coffeescript files in this example project
coffee --compile static/main.coffee &&\

# compile the coffeescript files in celestrium
coffee --compile -o static/celestrium_code/core/ static/celestrium_code/core-coffee/ 