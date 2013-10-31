This is the code for WikiNets. Feel free to contribute. It's available under a GNU GPL v3 license, the text of which is bundled, but in short: you're free to take this code and modify it as you wish, on the condition that you declare any changes you make, and pass on this freedom and responsibility in any release of your altered code. Also you should generally be nice.

Stable Version:
wikinets.herokuapp.com

Edge:
wikinets-edge.herokuapp.com

thewikinetsproject.wordpress.com


To Run Locally:
  Install neo4j http://www.neo4j.org/download

    Linux http://www.neo4j.org/download/linux:
    # start root shell
    sudo -s
    # Import our signing key
    wget -O - http://debian.neo4j.org/neotechnology.gpg.key | apt-key add - 
    # Create an Apt sources.list file
    echo 'deb http://debian.neo4j.org/repo stable/' > /etc/apt/sources.list.d/neo4j.list
    # Find out about the files in our repository
    apt-get update
    # Install Neo4j, community edition
    apt-get install neo4j
    # start neo4j server, available at http://localhost:7474 of the target machine
    neo4j start


  node web
  Browse to localhost:3000


Important Code Files
  myapp.coffee Server
  static/vizscript.js D3 Graph
  static/wikiscript.js Frontend JS, imports vizscript.js (assumes it will be there)
  public/index.jade HTML template



To setup on Heroku [todo]