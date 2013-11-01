## API

## Code

    define ["core/graphView"], (GraphView) ->

      class LinkFilter extends Backbone.Model
            consructor: (@graphView) ->
              @graphView.listenTo this, "change:threshold", @graphView.update
              @set "threshold", 1
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

      class LinkFilterAPI extends Backbone.Model
        consructor: () ->
          graphView = GraphView.getInstance()
          linkFilter = new LinkFilter(graphView)
