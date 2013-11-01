## API

## Code

    define ["core/graphView", "core/Singleton"], (GraphView, Singleton) ->

      class LinkFilter extends Backbone.Model
        constructor: (@graphView) ->
          super()
        initialize: () ->
          @graphView.listenTo this, "change:threshold", @graphView.update
          @set "threshold", 0.75
          @set "minThreshold", 0.75
          # adjust link strength and width based on threshold
          linkStrength = (link) =>
            return (link.strength - @get("threshold")) / (1.0 - @get("threshold"))
          @graphView.getForceLayout().linkStrength linkStrength
          updateStrokeWidth = (enterSelection) ->
            enterSelection.attr "stroke-width", (link) ->
              return 5 * linkStrength(link)
          @graphView.on "enter:link", updateStrokeWidth
          @on "change:threshold", ->
            updateStrokeWidth @graphView.getLinkSelection()
        filter: (links) ->
          return _.filter links, (link) =>
            return link.strength > @get("threshold")
        connectivity: (value) ->
          if value
            @set("threshold", value)
          else
            @get("threshold")
