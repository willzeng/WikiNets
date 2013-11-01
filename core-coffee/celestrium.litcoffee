## API

this is used to populate the listed singleton plugins with their single instance

other plugins may access this instance through requiring the module.

### Example

```coffeescript
require ["pluginPath"], (plugin) -> plugin.getInstance().foo()`
```

### Example Usage

Now in your `main` coffeescript file, you can do something like this.

```coffeescript
requirejs ["celestrium"], (Celestrium) ->
  Celestrium.init
    "core/workspace":
      "el": document.querySelector "#workspace"
```

only plugins which instantiate the `singleton` class should be used with `init`

## Code

    define [], () -> init: (singletonPlugins, callback) ->
      pluginPaths = _.keys(singletonPlugins)
      require pluginPaths, (plugins...) ->
        i = 0
        for plugin in plugins
          args = singletonPlugins[pluginPaths[i]]
          plugin.init args
          i += 1
        callback()
