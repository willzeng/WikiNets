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

Load the global libraries contained within celestrium here.
This offloads this responsibility from the user.

    globalLibs = [
      'lib/jquery',
      'lib/jquery.typeahead',
      'lib/underscore',
      'lib/backbone',
      'lib/d3',
    ]

The actual module returns only an object with an init method.

Load the above libraries so they are now available globally.

This is probably bad practice and less modular, but is practical.

    define globalLibs, () -> init: (singletonPlugins, callback) ->

Now actually require the different plugins.
Note that, they should all be required at once and the callback called within the require callback so as to ensure the callback is only call onced these plugin instances have been initialized.

        pluginPaths = _.keys(singletonPlugins)
        require pluginPaths, (plugins...) ->
          i = 0
          for plugin in plugins
            args = singletonPlugins[pluginPaths[i]]
            plugin.init args
            i += 1
          callback()
