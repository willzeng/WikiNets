###

only module that needs to be included by a user's requirejs main script.
also loads all the libraries with global definitions.
exposes an object with an `init` function which takes two arguments.

  1. dictionary of plugins
    - keys are singleton plugin requirejs paths
    - values are the arguments to that plugin's factory function
  2. callback
    - guaranteed to be called *after* all instances are created
      as well as globally defined libraries

###

requirejs.config
  shim:
    "../lib/jquery.typeahead": ["../lib/jquery"]
    "../lib/backbone": ["../lib/underscore"]
    "../lib/backbone-0.9.10": ["../lib/underscore"]
    "../lib/visualsearch":
      deps: ["../lib/jquery", "../lib/jquery.ui.autocomplete", "../lib/jquery.ui.core", "../lib/jquery.ui.menu", "../lib/jquery.ui.position", "../lib/jquery.ui.widget", "../lib/underscore", "../lib/backbone-0.9.10"]
      exports: 'VS'
    "../lib/jquery.ui.autocomplete": ["../lib/jquery.ui.core", "../lib/jquery.ui.menu", "../lib/jquery.ui.position", "../lib/jquery.ui.widget"]
    "../lib/jquery.ui.menu": ["../lib/jquery.ui.core", "../lib/jquery.ui.position", "../lib/jquery.ui.widget"]

globalLibs = [
  '../lib/jquery',
  '../lib/jquery.typeahead',
  '../lib/underscore',
  '../lib/backbone',
  '../lib/d3',
  '../lib/less',
  '../lib/visualsearch',
  '../lib/colorPicker/jquery.colorPicker'
]

define globalLibs, () ->
  init: (pluginsDict, callback) ->
    pluginPaths = _.keys(pluginsDict)
    instances = {}
    require pluginPaths, (plugins...) ->
      _.each plugins, (plugin, i) ->
        options = pluginsDict[pluginPaths[i]]
        instance = new plugin(options)
        instance.init instances
        instances[pluginPaths[i]] = instance
      window.instances = instances
      callback(instances) if callback?
