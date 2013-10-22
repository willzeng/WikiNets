# automatically add all possible links to the graph when a new node is added
define ["jquery"], ($) ->
  (graphModel, dataProvider) ->
    graphModel.on "add:node", (node) ->
      nodes = graphModel.getNodes()
      dataProvider.getLinks node, nodes, (links) ->
        _.each links, (strength, i) ->
          link =
            source: node
            target: nodes[i]
            strength: strength

          graphModel.putLink link  if link.strength > dataProvider.minThreshold



