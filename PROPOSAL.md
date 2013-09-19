An Interface to Understand Inference of Semantic Networks
===

## Abstract
MIT has aggregated a very large semantic network in ConceptNet as a result of its decade old Common Sense Computing Initiative. Divisi is a project out of MIT’s Media Lab which can make inferences on semantic networks, such as ConceptNet, thus generalizing the knowledge within the network and making it more useful. However, there are parameters of the inference process which can be adjusted and currently there is no good way of visualizing or understanding the results of the inference to see if it is making correct assumptions. Therefore, the proposed project is to create an interface which presents the results of the inference process to a user in a way in which they can understand if the process is arriving at reasonable conclusions. 

## Background
As advanced as computers have become, they still don’t understand simple, everyday facts that we take for granted, particularly in our communication and interactions with others. In an effort to bridge this gap and increase computers’ ability to understand common knowledge, MIT’s Media Lab started the [Common Sense Computing Initiative](http://csc.media.mit.edu/) over a decade ago. This project offers a web interface for anyone to submit simple, common sense statements and has accrued over one million of such statements. 

These concepts are housed in a project called [ConceptNet](http://csc.media.mit.edu/conceptnet). ConceptNet provides programmatic access the common sense statements people have submitted. Specifically, the knowledge is represented as a graph where the nodes concepts and edges are relations between concepts. Additionally, submissions are first normalized so variations in the natural language representation of the same concept still result in a the same underlying concept in ConceptNet. Figure 1 shows an example of a small semantic network.

<div align="center">
  
  <img src="http://anemone.media.mit.edu/sites/default/files/images/cnetpic.preview.png"/>

  <div>
    <b>Fig 1.</b> Example Semantic Network Taken from <a href="http://csc.media.mit.edu/conceptnet">ConceptNet</a>
  </div>
</div>


While ConceptNet does have an incredible amount of information in it, if a particular fact was not specifically entered, then querying ConceptNet for it will result in no information. To overcome this, [Divisi](http://csc.media.mit.edu/divisi) is another project out the Media Lab and can make inferences on semantic networks. Conceptually, it is similar to smoothing the information so even if a specific fact isn’t in ConceptNet, using Dvisi’s inference algorithm it will detect if similar facts have been entered and respond accordingly. This generalizability greatly improves the usability of ConceptNet’s knowledge base.

However, there are parameters that must be set for the inference process and it remains an open problem to find a way to present the results of the inference process to a non-technical user in a way in which they can understand it. There are visualizations of the similarities of certain concepts which can be derived as a side effect of the inference process. However, this is not a great indication of how successful the inference was at concluding truthful assertions as only concepts are shown, not the assertions themselves. This leads to the proposed work.

## Proposed Work
To enable users to better understand the results of Divisi’s inference process, an interface will be built which visualizes its results. This will certainly be an iterative process, but the initial design is to render a central assertion as well as related assertions and illustrate their confidences. Specifically, it will use a web based approach, leveraging d3js’s force layout to render a graph where each node represents an assertion, nodes’ proximities represent how related they are and color represents how confident Divisi is in that assertion. All of these properties are available as part of d3js’s API. However, it remains to be seen the best way to determine how related two assertions are. Again, it will be an iterative process in refining this answer but the initial concept will be implement a blending function of the relatedness of the concepts and relations of each assertion.

Additionally, there is a parameter of the inference process which relates to how liberal or conservative it is in making assumptions. The proposed interface will have the ability to change this parameter and visualize the change in the graph structure live. Again, d3js has support for dynamic visualizations but the infrastructure to provide that data from Divisi must be created as well as ensuring the inference process performs quickly enough to make a live visualization worthwhile. Most likely the ability to precompute the results of inference at various levels of liberalness will need to be implemented.

In summary, this project aims to create a web based interface to help users better understand how effective Divisi’s inference is and let the user adjust settings to improve results.
