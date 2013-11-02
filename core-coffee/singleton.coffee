## API

This provides a base class for singleton modules to allow their single instance to easily be created and accessed.

### Examples

So you should be able to simply extend `Singleton` and make the constructor

This should hopefully lend itself to the following design pattern

```coffeescript
define ['core/singleton', 'backbone'], (Singleton, Backbone) ->

  #
  class Plugin extends Backone.Model
    constructor: () ->

  # make this plugin's singleton accessible
  # coffeescript will then also return the return value below, which is Plugin
  _.extends(Plugin, Singleton);

```

### Old Full Example That Worked

the base class which singleton plugins should extend

This is an **example** and it works, so just wanted to save it.

```coffeescript
class Singleton

Singleton.init = (args) ->
  @instance = new this(args)

Singleton.getInstance = () ->
  if @instance?
    return @instance
  else
    throw "instance undefined"

class Workspace extends Singleton
  constructor: (@el) ->

class GraphModel extends Singleton
  constructor: (@bar) ->

Workspace.init("elmo")
GraphModel.init("beerios")
```

## Code

    define [], () ->
      class Singleton
        @init: (args) ->
          @instance = new this(args)
        @getInstance: () ->
          if @instance?
            return @instance
          else
            throw "instance undefined"
