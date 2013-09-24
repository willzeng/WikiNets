import os
import divisi2
import cherrypy
import sys
import simplejson as json

class ConceptProvider(object):
  
  def __init__(self, num_axes):
    A = divisi2.network.conceptnet_matrix('en')
    concept_axes, axis_weights, feature_axes = A.svd(k=num_axes)
    self.sim = divisi2.reconstruct_similarity(concept_axes, axis_weights, post_normalize=True)  
    self.concept_axes = concept_axes

  def get_concepts(self):
    '''returns list of strings of concepts'''
    return [x for x in self.concept_axes.row_labels]

  def get_links(self, concept, otherConcepts):
    return [self.sim.entry_named(concept, c2) for c2 in otherConcepts]

  '''
  def get_related_concepts(self, text, limit):
    return self.sim.row_named(text).top_items(n=limit)

  def get_concepts(self):
    return self.sim.row_named

  def get_data(self, text):

    # helper function
    def get_related_nodes(node):
      return [n for (n, x) in self.sim.row_named(node).top_items()]

    # gather concepts and their relatedness as nodes and links

    text = text.lower().strip()
    nodesSet = {text}
    currentLevel = [text]
    numLevels = 3

    for i in xrange(numLevels):
      nextLevel = []
      for node in currentLevel:
        relatedNodes = get_related_nodes(node)
        for relatedNode in relatedNodes:
          if relatedNode not in nodesSet:
            nodesSet.add(relatedNode)
            nextLevel.append(relatedNode)
      currentLevel = nextLevel

    nodesList = list(nodesSet)
    links = []

    for i in xrange(len(nodesList) - 1):
      for j in xrange(i + 1, len(nodesList)):
        n1 = nodesList[i]
        n2 = nodesList[j]
        strength = self.sim.entry_named(n1, n2)
        strength = max(0, strength)
        strength = min(1, strength)
        if strength > .75:
          links.append({'source': i, 
                        'target': j, 
                        'strength': strength})

    nodes = [{'text': node} for node in nodesList]

    return {"nodes": nodes, "links": links}

  def get_link_strengths(self, node, otherNodes):
    return [{"strength": self.sim.entry_named(node, otherNode)} for otherNode in otherNodes]

  def get_top_items(self, node, limit):
    output = []
    for node, strength in self.sim.row_named(node).top_items(n=limit):
      output.append({"text": node, "strength": strength})
    return output
  '''

class Server(object):
  _cp_config = {'tools.staticdir.on' : True,
                'tools.staticdir.dir' : os.path.abspath(os.path.join(os.getcwd(), "web")),
                'tools.staticdir.index' : 'index.html',
                }

  def __init__(self):
    self.provider = ConceptProvider(100)


  @cherrypy.expose
  @cherrypy.tools.json_out()
  def get_concepts(self):
    return self.provider.get_concepts();

  @cherrypy.expose
  @cherrypy.tools.json_out()
  def get_links(self, text, allNodes):
    return self.provider.get_links(text, json.loads(allNodes))

  '''

  @cherrypy.expose
  @cherrypy.tools.json_out()
  def get_related_concepts(self, text, limit=10):
      return self.provider.get_related_concepts(text, int(limit))

  @cherrypy.expose
  @cherrypy.tools.json_out()
  def get_data(self, text):
    return self.provider.get_data(text)

  @cherrypy.expose
  @cherrypy.tools.json_out()
  def get_link_strengths(self, nextNode, currentNodes):
    return {"links": self.provider.get_link_strengths(nextNode, json.loads(currentNodes))}

  @cherrypy.expose
  @cherrypy.tools.json_out()
  def test(self, a, b):
    return json.loads(b)[0]

  @cherrypy.expose
  @cherrypy.tools.json_out()
  def get_top_items(self, text, limit=10):
    return {"related": self.provider.get_top_items(text, int(limit))}

  '''


cherrypy.config.update({'server.socket_host': '0.0.0.0', 
                         'server.socket_port': int(sys.argv[1]), 
                        }) 

cherrypy.quickstart(Server())
