# interface which singleton plugins should extend, like so
# `_.extend YourPluginClass, Singleton`
# the singleton plugin's constuctor should accept an argument
# which is the argument supplied as the value
# in the dictionary supplied to Celestrium.init
define [], () ->
  class Singleton
    @init: (args) ->
      @instance = new this(args)
    @getInstance: () ->
      if @instance?
        return @instance
      else
        throw "instance undefined"
