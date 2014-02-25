### This is the main file that constructs the client-side application ###
# It builds an object called Celestrium that has plugins to provide functionality.

# tell requirejs where everything is
requirejs.config

  #This is where all the plugins and Celestrium itself are located
  baseUrl: "/core/"

  # paths tells requirejs to replace the keys with their values
  # in subsequent calls to require
  paths:

    #This is another path where you could put your own local plugins
    local: "."

###

You need only require the Celestrium plugin.
NOTE: it's module loads the globally defined standard js libraries
      like jQuery, underscore, etc...
###

require ["Celestrium"], (Celestrium) ->

  ###

  This dictionary defines which plugins are to be included
  and what their arguments are.

  The key is the requirejs path to the plugin.
  The value is passed to its constructor.

  ###
  
  plugins =

    # listens for keystroke on the dom element it's given
    KeyListener:
      document.querySelector("body")

    # stores the actual nodes and links of the graph
    GraphModel:
      nodeHash: (node) -> node['_id']
      linkHash: (link) -> if link['_id']? then link['_id'] else 0

    # renders the graph using d3's force directedlayout
    GraphView: {}

    # this controls edits to the Neo4j database
    "local/Neo4jDataController": {}

    # provides functions to get nodes and links from the Neo4j database
    "local/WikiNetsDataProvider": {}

    # renders the graph in a pseudo-list view
    #"local/ListView": {}
      
    # allows nodes to be selected
    NodeSelection: {}
      
    # allows links to be selected
    LinkSelection: {}

    # Build the faceted Visual Search box
    #"local/VisualSearch": {}
    
    # Is a full text search box
    "local/SimpleSearchBox": {}

    # Displays selected node details and allows editing
    "local/NodeEdit": {}

    # Displays selected link details and allows editing
    "local/LinkEdit": {}

    # This builds the toolbox in the botton right
    # with functionality to control the graph layout and behavior
    # some other plugins are added to this toolbox
    "local/ToolBox": {}

    # Adds a topbar with link/node creation functionality
    # and the "#toplink-instructions" box
    "local/TopBarCreate": {}

    # adds a dropdown menu on the top left with 
    # About information and some basic display commands
    DropdownMenu: {}

    # Allows you to get the neighbors of a nodes
    # currently implemented by right click
    Expander: {}

    # This shows the name of a link on hover
    LinkHover: {}

    # appends a minimap plugin to the ToolBox
    MiniMap: {}  

    # adds a slider plugin to the ToolBox
    "Sliders": {}

    # adds a slider to change the force for the graph
    "ForceSliders": {}

    # adds a popout creation functionality to TopBarCreate
    "local/NodeCreationPopout": {}

    # is a plugin that filters the graphview based on link.strength
    #"LinkDistribution": {}

  # initialize the plugins and execute a callback once done
  Celestrium.init plugins, (instances) ->

    loadEverything = (nodes) -> 
      instances["GraphModel"].putNode node for node in nodes

    #Prepopulate the GraphModel with all the nodes and links
    $.get('/get_default_nodes', loadEverything)

    # this allows all link strengths to be visible
    instances["GraphView"].getLinkFilter().set("threshold", 0)
