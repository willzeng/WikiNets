// automatically add all possible links to the graph when a new node is added
define(['jquery'], function($) {

  return function(graphModel, dataProvider) {
    graphModel.on("add:node", function(node) {
      var nodes = graphModel.getNodes();
      dataProvider.getLinks(node, nodes, function(links) {
        _.each(links, function(strength, i) {
          var link = {source:node, target: nodes[i], strength: strength};
          if (link.strength > dataProvider.minThreshold) {
            graphModel.putLink(link);
          }
        });
      });
    });
  };

});