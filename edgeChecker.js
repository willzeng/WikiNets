define(['jquery'], function($) {

  return function(graphModel, dataProvider) {
    graphModel.on("add:node", function(node) {
      dataProvider.addEdges(node)
    });
  }

});