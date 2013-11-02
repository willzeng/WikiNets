define ["core/graphView", "core/Singleton"], (GraphView, Singleton) ->

  class LinkFilter extends Backbone.Model
    initialize: () ->
      @set "threshold", 0.75
      @set "minThreshold", 0.75
    filter: (links) ->
      return _.filter links, (link) =>
        return link.strength > @get("threshold")
    connectivity: (value) ->
      if value
        @set("threshold", value)
      else
        @get("threshold")
