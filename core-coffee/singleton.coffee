define [], () ->
  class Singleton
    @init: (args) ->
      @instance = new this(args)
    @getInstance: () ->
      if @instance?
        return @instance
      else
        throw "instance undefined"
