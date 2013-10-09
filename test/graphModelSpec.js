define(['src/graphModel'], function(GraphModel) {

  describe('graph model', function() {

    it('can be created', function() {
      var g = new GraphModel();
    });

    describe('adding single node', function() {
      var g = new GraphModel({
        nodeHash: function(node) {
          return node.text;
        },
      });

      var node = {text: "testing text"};
      
      var changeListener = jasmine.createSpy('changeListener');
      var changeNodesListener = jasmine.createSpy("changeNodesListener");
      var addNodeListener = jasmine.createSpy("addNodeListener");

      g.on("change", changeListener);
      g.on("change:nodes", changeNodesListener);
      g.on("add:node", addNodeListener);

      it('can add node', function() {
        g.putNode(node);
      });
        
      it('triggers change, chagne:nodes and add:node', function() {
        expect(changeListener).toHaveBeenCalled();
        expect(changeNodesListener).toHaveBeenCalled();
        expect(addNodeListener).toHaveBeenCalled();
      });

      it('triggers change, change:nodes and add:node exactly once', function() {
        expect(changeListener.calls.length).toEqual(1);
        expect(changeNodesListener.calls.length).toEqual(1);
        expect(addNodeListener.calls.length).toEqual(1);
      });

      it("triggers add:node with reference to actual node", function() {
        expect(addNodeListener.mostRecentCall.args[0]).toBe(node);
      });

      describe("then getting nodes", function() {
        var nodes = g.getNodes();

        it("leads to the correct number of nodes in the array", function() {
          expect(nodes.length).toEqual(1);
        });

        it("leads to a reference of the actual node in the array", function() {
          expect(nodes[0]).toBe(node);
        })
      });
    });

    describe("adding a copy of the same node twice", function() {
      it("doesn't duplicate nodes", function() {
        var g = new GraphModel({
          nodeHash: function(node) {
            return node.text;
          },
        });
        var node1 = {text: "same text"};
        g.putNode(node1);
        var changeListener = jasmine.createSpy("changeListener");
        var changeNodesListener = jasmine.createSpy("changeNodesListener");
        g.on("change", changeListener);
        g.on("change:nodes", changeNodesListener)
        var node2 = {text: "same text"};
        g.putNode(node2);
        expect(changeListener).not.toHaveBeenCalled();
      });
    });

  });

});