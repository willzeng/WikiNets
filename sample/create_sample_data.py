import divisi2
import simplejson

''' Script which generates sample data for visualization prototype '''

# use conceptnet information
A = divisi2.network.conceptnet_matrix('en')

# perform SVD
concept_axes, axis_weights, feature_axes = A.svd(k=100)

# calculate similarity matrix
sim = divisi2.reconstruct_similarity(concept_axes, axis_weights, post_normalize=True)

# helper function
def get_related_nodes(node):
  return [n for (n, x) in sim.row_named(node).top_items()]

# gather relatd
centralConcept = 'school'
nodesSet = {centralConcept}
currentLevel = [centralConcept]
numLevels = 3

# gather concepts and their relatedness as nodes and links
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
    strength = sim.entry_named(n1, n2)
    strength = max(0, strength)
    strength = min(1, strength)
    if strength > .75:
      links.append({'source': i, 
                    'target': j, 
                    'strength': strength})

# serialize to json and write to file
nodes = [{'text': node} for node in nodesList]
open('sample_nodes.js', 'w').write('nodes = ' + simplejson.dumps(nodes))
open('sample_links.js', 'w').write('links = ' + simplejson.dumps(links))
