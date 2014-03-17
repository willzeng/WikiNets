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
    "../lib/jquery.typeahead": ["./jquery"]
    "../lib/backbone": ["./underscore"]
    "../lib/VisualSearch/visualsearch":
      deps: ["../jquery", "./jquery.ui.autocomplete", "./jquery.ui.core", "./jquery.ui.menu", "./jquery.ui.position", "./jquery.ui.widget", "../underscore", "../backbone"]
      exports: 'VS'
    "../lib/VisualSearch/jquery.ui.core": ["../jquery"]
    "../lib/VisualSearch/jquery.ui.position": ["../jquery"]
    "../lib/VisualSearch/jquery.ui.widget": ["../jquery"]
    "../lib/VisualSearch/jquery.ui.autocomplete": ["./jquery.ui.core", "./jquery.ui.menu", "./jquery.ui.position", "./jquery.ui.widget"]
    "../lib/VisualSearch/jquery.ui.menu": ["./jquery.ui.core", "./jquery.ui.position", "./jquery.ui.widget"]
    "../lib/colorPicker/jquery.colorPicker": ["../jquery"]

globalLibs = [
  '../lib/jquery',
  '../lib/jquery.typeahead',
  '../lib/underscore',
  '../lib/backbone',
  '../lib/d3',
  '../lib/less',
  '../lib/VisualSearch/visualsearch',
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
