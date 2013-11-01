## API

TODO - sorry

## Code

    define ["core/singleton"], (Singleton) ->

      class GraphModel extends Backbone.Model

        initialize: ->
          @set "nodes", []
          @set "links", []
          @set "nodeSet", {}

        getNodes: ->
          return @get "nodes"

        getLinks: ->
          return @get "links"

        putNode: (node) ->
          # ignore if node is already in this graph
          return  if @get("nodeSet")[@get("nodeHash")(node)]

          # modify node to have attribute accessor functions
          nodeAttributes = @get("nodeAttributes")
          node.getAttributeValue = (attr) ->
            nodeAttributes[attr].getValue node

          # commit this node to this graph
          @get("nodeSet")[@get("nodeHash")(node)] = true
          @trigger "add:node", node
          @pushDatum "nodes", node

        putLink: (link) ->
          @pushDatum "links", link
          @trigger "add:link", link

        pushDatum: (attr, datum) ->
          data = @get(attr)
          data.push datum
          @set attr, data

QA: this is not already fired because of the rep-exposure of get.
`data` is the actual underlying object
so even though set performs a deep search to detect changes,
it will not detect any because it's literally comparing the same object.

Note: at least we know this will never be a redundant trigger

          @trigger "change:#{attr}"
          @trigger "change"

        # also removes links incident to any node which is removed
        filterNodes: (filter) ->
          nodeWasRemoved = (node) ->
            _.some removed, (n) ->
              _.isEqual n, node

          linkFilter = (link) ->
            not nodeWasRemoved(link.source) and not nodeWasRemoved(link.target)
          removed = []
          wrappedFilter = (d) =>
            decision = filter(d)
            unless decision
              removed.push d
              delete @get("nodeSet")[@get("nodeHash")(d)]
            decision
          @filterAttribute "nodes", wrappedFilter
          @filterLinks linkFilter

        filterLinks: (filter) ->
          @filterAttribute "links", filter

        filterAttribute: (attr, filter) ->
          filteredData = _.filter(@get(attr), filter)
          @set attr, filteredData

      class GraphModelAPI extends GraphModel
      _.extend GraphModelAPI, Singleton
