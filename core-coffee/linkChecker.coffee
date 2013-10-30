# automatically add all possible links to the graph when a new node is added
define ["jquery"], ($) ->
  (graphModel, dataProvider) ->
    graphModel.on "add:node", (node) ->
      nodes = graphModel.getNodes()
      dataProvider.getLinks node, nodes, (links) ->
        _.each links, (coeffs, i) ->
          link =
            source: node
            target: nodes[i]
            coeffs: coeffs

          graphModel.putLink link if !dataProvider.filter? or dataProvider.filter(link)
