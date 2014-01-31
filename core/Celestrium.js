// Generated by CoffeeScript 1.6.3
/*

only module that needs to be included by a user's requirejs main script.
also loads all the libraries with global definitions.
exposes an object with an `init` function which takes two arguments.

  1. dictionary of plugins
    - keys are singleton plugin requirejs paths
    - values are the arguments to that plugin's factory function
  2. callback
    - guaranteed to be called *after* all instances are created
      as well as globally defined libraries
*/


(function() {
  var globalLibs,
    __slice = [].slice;

  requirejs.config({
    shim: {
      "../lib/jquery.typeahead": ["../lib/jquery"],
      "../lib/backbone": ["../lib/underscore"],
      "../lib/backbone-0.9.10": ["../lib/underscore"],
      "../lib/visualsearch": {
        deps: ["../lib/jquery", "../lib/jquery.ui.autocomplete", "../lib/jquery.ui.core", "../lib/jquery.ui.menu", "../lib/jquery.ui.position", "../lib/jquery.ui.widget", "../lib/underscore", "../lib/backbone-0.9.10"],
        exports: 'VS'
      },
      "../lib/jquery.ui.autocomplete": ["../lib/jquery.ui.core", "../lib/jquery.ui.menu", "../lib/jquery.ui.position", "../lib/jquery.ui.widget"],
      "../lib/jquery.ui.menu": ["../lib/jquery.ui.core", "../lib/jquery.ui.position", "../lib/jquery.ui.widget"]
    }
  });

  globalLibs = ['../lib/jquery', '../lib/jquery.typeahead', '../lib/underscore', '../lib/backbone', '../lib/d3', '../lib/less', '../lib/visualsearch', '../lib/colorPicker/jquery.colorPicker'];

  define(globalLibs, function() {
    return {
      init: function(pluginsDict, callback) {
        var instances, pluginPaths;
        pluginPaths = _.keys(pluginsDict);
        instances = {};
        return require(pluginPaths, function() {
          var plugins;
          plugins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _.each(plugins, function(plugin, i) {
            var instance, options;
            options = pluginsDict[pluginPaths[i]];
            instance = new plugin(options);
            instance.init(instances);
            return instances[pluginPaths[i]] = instance;
          });
          window.instances = instances;
          if (callback != null) {
            return callback(instances);
          }
        });
      }
    };
  });

}).call(this);
