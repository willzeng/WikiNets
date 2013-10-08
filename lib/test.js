var requirejs = require('requirejs');

requirejs.config({
  nodeRequire: require,
});

requirejs(['./celestrium/graphModel.js'],
function   (GraphModel) {
    //foo and bar are loaded according to requirejs
    //config, but if not found, then node's require
    //is used to load the module.
});