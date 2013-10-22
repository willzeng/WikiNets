define ["core/graphModel"], (GraphModel) ->
  describe "graph model", ->
    it "can be created", ->
      g = new GraphModel()

    describe "adding single node", ->
      g = new GraphModel(nodeHash: (node) ->
        node.text
      )
      node = text: "testing text"
      changeListener = jasmine.createSpy("changeListener")
      changeNodesListener = jasmine.createSpy("changeNodesListener")
      addNodeListener = jasmine.createSpy("addNodeListener")
      g.on "change", changeListener
      g.on "change:nodes", changeNodesListener
      g.on "add:node", addNodeListener
      it "can add node", ->
        g.putNode node

      it "triggers change, chagne:nodes and add:node", ->
        expect(changeListener).toHaveBeenCalled()
        expect(changeNodesListener).toHaveBeenCalled()
        expect(addNodeListener).toHaveBeenCalled()

      it "triggers change, change:nodes and add:node exactly once", ->
        expect(changeListener.calls.length).toEqual 1
        expect(changeNodesListener.calls.length).toEqual 1
        expect(addNodeListener.calls.length).toEqual 1

      it "triggers add:node with reference to actual node", ->
        expect(addNodeListener.mostRecentCall.args[0]).toBe node

      describe "then getting nodes", ->
        nodes = g.getNodes()
        it "leads to the correct number of nodes in the array", ->
          expect(nodes.length).toEqual 1

        it "leads to a reference of the actual node in the array", ->
          expect(nodes[0]).toBe node



    describe "adding a copy of the same node twice", ->
      it "doesn't duplicate nodes", ->
        g = new GraphModel(nodeHash: (node) ->
          node.text
        )
        node1 = text: "same text"
        g.putNode node1
        changeListener = jasmine.createSpy("changeListener")
        changeNodesListener = jasmine.createSpy("changeNodesListener")
        g.on "change", changeListener
        g.on "change:nodes", changeNodesListener
        node2 = text: "same text"
        g.putNode node2
        expect(changeListener).not.toHaveBeenCalled()




