requirejs.config
  shim:
    "lib/jquery.typeahead": ["lib/jquery"]
    "lib/backbone": ["lib/underscore"]

globalLibs = [
  'lib/jquery',
  'lib/jquery.typeahead',
  'lib/underscore',
  'lib/backbone',
  'lib/d3',
]

define globalLibs, () -> init: (singletonPlugins, callback) ->
  pluginPaths = _.keys(singletonPlugins)
  require pluginPaths, (plugins...) ->
    i = 0
    for plugin in plugins
      args = singletonPlugins[pluginPaths[i]]
      plugin.init args
      i += 1
    callback()
