<!DOCTYPE html>
<meta charset="utf-8">

<style> 

  h1 a{
    color:black;
    text-decoration:none;
  }

  h1 a:hover{
  background:#e3edef;
  }

  .node {
    stroke: #fff;
    stroke-width: 1.5px;
  }

  .link {
    stroke: #999;
    stroke-opacity: .6;
  }

  ul, li{margin:0; border:0; padding:0; list-style:none;}
  #middlebar{
  font-size:12px;
  color:#3b5d14;
  background:white;
  font-weight:bold;
  padding:4px;
  height:30px;
  width: 180px;
  float:left;
  margin-left: 40px;
  }
  #middlebar .menu li {
  height:30px;
  float:left;
  margin-right:10px;
  }
  #middlebar .menu li a{
  color:#3b5d14;
  text-decoration:none;
  padding:0 10px;
  height:30px;
  line-height:30px;
  display:block;
  float:left;
  padding:0 26px 0 10px;
  }
  #middlebar .menu li a:hover{
  color:#666666;
  }

  #middlebar ul .submenu {
  border:solid 1px #c9dea1;
  border-top:none;
  background:#FFFFFF;
  position:relative;
  top:4px;
  width:200px;
  padding:6px 0;
  clear:both;
  z-index:2;
  display:none;
  }
  #middlebar ul .submenu li{
  background:none;
  display:block;
  float:none;
  margin:0 6px;
  border:0;
  height:auto;
  line-height:normal;
  border-top:solid 1px #DEDEDE;
  }
  #middlebar .submenu li a{
  background:none;
  display:block;
  float:none;
  padding:6px 6px;
  margin:0;
  border:0;
  height:auto;
  color:#105cbe;
  line-height:normal;
  }
  #middlebar .submenu li a:hover{
  background:#e3edef;
  }

  ul, li{margin:0; border:0; padding:0; list-style:none;}
  #infobar{
  font-size:12px;
  color:#3b5d14;
  background:white;
  font-weight:bold;
  padding:4px;
  height:30px;
  width: 380px;
  float:left;
  margin-left: 40px;
  }
  #infobar .menu li {
  height:30px;
  float:left;
  margin-right:10px;
  }
  #infobar .menu li a{
  color:#3b5d14;
  text-decoration:none;
  padding:0 10px;
  height:30px;
  line-height:30px;
  display:block;
  float:left;
  padding:0 26px 0 10px;
  }
  #infobar .menu li a:hover{
  color:#666666;
  }

  #infobar ul .submenu {
  border:solid 1px #c9dea1;
  border-top:none;
  background:#FFFFFF;
  position:relative;
  top:4px;
  width:380px;
  padding:6px 0;
  clear:both;
  z-index:2;
  display:none;
  }
  #infobar ul .submenu li{
  background:none;
  display:block;
  float:none;
  margin:0 6px;
  border:0;
  height:auto;
  line-height:normal;
  border-top:solid 1px #DEDEDE;
  }
  #infobar .submenu li a{
  background:none;
  display:block;
  float:none;
  padding:6px 6px;
  margin:0;
  border:0;
  height:auto;
  color:#105cbe;
  line-height:normal;
  }
  #infobar .submenu li a:hover{
  background:#e3edef;
  }
</style>

  <script type="text/JavaScript" src="jquery-1.10.2.js"></script>
<script type="text/JavaScript">
    // this is currently a bit of a hack of jQuery and non-jQuery code.
    // Not sure how to convert it all into jQuery though...
    // Code for adding more input fields modified from http://www.quirksmode.org/dom/domform.html
    var counter = 0;

    function moreFields(writediv, rootdiv, classNamediv) {
  counter++;
  var newFields = document.getElementById(rootdiv).cloneNode(true);
  newFields.id = '';
  newFields.className = classNamediv;
  newFields.style.display = 'block';
  var newField = newFields.childNodes;
  for (var i=0;i<newField.length;i++) {
    var theName = newField[i].name
    if (theName)
      newField[i].name = theName + counter;
  }
  var insertHere = document.getElementById(writediv);
  insertHere.parentNode.insertBefore(newFields,insertHere);
    }

    //window.onload = moreFields('writeroot');

  var restServerURL = "http://993f61a8c.hosted.neo4j.org:7485/";

  $(document).ready(function(){
    $("#createObj").on("click", function(event){
      var nodeObject = {};
      $('.nodeProperty').each(function(i, obj) {
  var property = $(this).children(".propertyObj").val();
  var value = $(this).children(".valueObj").val();
  // should probably do some input validation here:
  // currently, if the same property is assigned twice, the value is just overwritten
  // also might want to look out for security issues -- but I don't know what to look out for
  nodeObject[property] = value;
      });
      //$("#output").append(JSON.stringify(nodeObject));
      $.ajax({
  type: "POST",
  username: "6f60436c5",
  password: "9d6fe0c2a",
  url: restServerURL + "/node",
  data: JSON.stringify(nodeObject),
  dataType: "json",
  contentType: "application/json",
  success: function( data, xhr, textStatus ) {
    window.console && console.log( data + xhr + textStatus );
  },
  error: function( xhr ) {
    alert("Error!");
    window.console && console.log( xhr );
  },
  complete: function( data ) {
    var mydata = $.parseJSON(data.responseText);
    alert( "Address of new node: " +  mydata.self );
  }
      });
    });
  });

  </script>

  <script type="text/JavaScript">

  $(document).ready(function(){
    $("form#get-node").submit(function(){
        // should do some input checking here to make sure input is a number
      $.ajax({
        type: "GET",
        url: restServerURL + "/node/" + $("#node-id").val(),
        contentType: "application/json",
        success: function( data, xhr, textStatus ) {
          window.console && console.log( data + xhr + textStatus );
        },
        error: function( xhr ) {
          alert("Error!");
          window.console && console.log( xhr );
        },
        complete: function( data ) {
          var mydata = $.parseJSON(data.responseText).data;
          //alert( "Properties of node: " + JSON.stringify(mydata));
          $("#SearchOutput").append(JSON.stringify(mydata, undefined, "<br />"));
        }
      });
      return false;
    });
  });
  </script>

<body>

  <script src="http://d3js.org/d3.v3.min.js"></script>

  <script type="text/javascript">
  function showlayer(layer){
    var myLayer = document.getElementById(layer);
    if(myLayer.style.display=="none" || myLayer.style.display==""){
      myLayer.style.display="block";
    } else { 
      myLayer.style.display="none";
    }
  }
  </script>

  <div id="header" style="background-color:white;">
    <h1 style="margin-bottom:5px;margin-left:10px;"><a href="http://thewikinetsproject.wordpress.com/">WikiNets</a></h1>
  </div>

  
  <div id="edit_menu" style="display:none;">

  <div id="infobar">
    <ul class="menu">
       <li><a href="#" onclick="javascript:showlayer('en_1')"> Edit Node/Arrow</a>
       </li>
      <ul class="submenu" id="en_1">
        <li>
        <a href="p1.html">Edit</a> Here is where you will go to input information to edit a node or morphism.</li>
      </ul>
    </ul>
  </div>

  <div id="infobar">

    <ul class="menu">
      <li><a href="#" onclick="javascript:showlayer('enn_1')"> Add Node/Arrow </a></li>
      <ul class="submenu" id="enn_1">
          <li>Create node:</li>
            <div id="readrootObj" style="display: none">
              <input class="propertyObj" name="propertyObj" value="propertyEx" />
              <input class="valueObj" name="valueObj" value="valueEx" />
              <input type="button" value="x" onclick="this.parentNode.parentNode.removeChild(this.parentNode);" /><br />
            </div>

            <form id="create-node">
              <span id="writerootObj"></span>
            </form>

            <input type="button" id="moreFields" value="+" onclick="moreFields('writerootObj','readrootObj','nodeProperty')"/>
            <div style="float:right;"><input type="button" id="createObj" value="Create node" /></div>

            <div id="output"></div>

          <li> Create arrow:</li>

            <div id="readrootArr" style="display: none">
              <input class="propertyArr" name="propertyArr" value="property" />
              <input class="valueArr" name="valueArr" value="value" />
              <input type="button" value="x" onclick="this.parentNode.parentNode.removeChild(this.parentNode);" /><br />
            </div>

            <form id="create-rel">
            <div>
              <input id="from" name="from" value="from: node ID" />
              <input id="to" name="to" value="to: node ID" />
            </div><br />
              <span id="writerootArr"></span>
            </form>

            <input type="button" id="moreFields" value="+" onclick="moreFields('writerootArr','readrootArr','relProperty')"/>
           <div style="float:right;"> <input type="button" id="create" value="Create arrow" /></div>

            <div id="output"></div>

      </ul>
    </ul>
  </div> 

  <div id="spacer" style="width:20px;height:30px;float:left;">
  </div>

<a href="#" onclick="javascript:showlayer('browse_menu');javascript:showlayer('edit_menu')"><img src="search.png" alt="Open the Edit Network menu."></a>

</div>

 <div id="browse_menu" style="display:block;">

  <div id="middlebar">
    <ul class="menu">
       <li><a href="#" onclick="javascript:showlayer('sm_1')"> Search</a>
       </li>
      <ul class="submenu" id="sm_1">
        <li>Node ID:</li>
          <form id="get-node">
          <input type="text" size="27" id="node-id" />
          <input type="submit" id="get-n" value="Get node">
          </form>
          <div id="SearchOutput"></div>
        </li>
      </ul>
    </ul>
  </div>

  <div id="middlebar">

    <ul class="menu">
      <li><a href="#" onclick="javascript:showlayer('sm_2')"> Toggle </a></li>
      <ul class="submenu" id="sm_2">
        <li>
        <a href="p1.html">Toggle</a> Here is where a toggle box with options will go.</li>
      </ul>
    </ul>
  </div> 

  <div id="infobar">

    <ul class="menu">
      <li><a href="#" onclick="javascript:showlayer('sm_3')"> Info: ExampleNode</a></li>
      <ul class="submenu" id="sm_3">
        <li><a href="p1.html">Information</a> Here there is plenty of room to put all sorts of example information about some particular node.  There could be citations too<sup>1</sup> perhaps. </li>
        <li><a href="p2.hmtl">Bibliography </a> 1. Will et. al. "Some Example Paper", Phys. Rev. Letters. 11-2229.</li>
      </ul>
    </ul>
  </div>

  <a href="#" onclick="javascript:showlayer('edit_menu');javascript:showlayer('browse_menu')"><img src="plus.png" alt="Open the Edit Network menu."></a>

  </div>

  <script>

  var width = 960,
      height = 500;

  var color = d3.scale.category20();

  var force = d3.layout.force()
      .charge(-120)
      .linkDistance(30)
      .size([width, height]);

  var svg = d3.select("body").append("svg")
      .attr("width", width)
      .attr("height", height);

  d3.json("miserables.json", function(error, graph) {
    force
        .nodes(graph.nodes)
        .links(graph.links)
        .start();

    var link = svg.selectAll(".link")
        .data(graph.links)
      .enter().append("line")
        .attr("class", "link")
        .style("stroke-width", function(d) { return Math.sqrt(d.value); });

    var node = svg.selectAll(".node")
        .data(graph.nodes)
      .enter().append("circle")
        .attr("class", "node")
        .attr("r", 5)
        .style("fill", function(d) { return color(d.group); })
        .call(force.drag);

    node.append("title")
        .text(function(d) { return d.name; });

    force.on("tick", function() {
      link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });

      node.attr("cx", function(d) { return d.x; })
          .attr("cy", function(d) { return d.y; });
    });
  });

  </script>


  <div id="footer" style="clear:both;text-align:center;font-size:12px;font-weight:bold;">
    <a href="http://thewikinetsproject.wordpress.com">About</a> | 
    <a href="http://thewikinetsproject.wordpress.com/about/">Contact</a>
  </div>

</body>
</html>