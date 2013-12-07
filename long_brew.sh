#!/bin/sh

# compile the coffeescript files in this example project
coffee --compile -w static/ &&\

# compile the coffeescript files in celestrium
coffee --compile -w -o static/celestrium_code/core/ static/celestrium_code/core-coffee/ 