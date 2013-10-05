// automatically add all possible links to the graph when a new node is added
define(['jquery'], function($) {

  return function(graphModel, dataProvider) {
    graphModel.on("add:node", function(node) {
      dataProvider.addLinks(node)
    });
  }

});