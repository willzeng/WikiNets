// toggles whether the given layer is visible
function showlayer(layer){
  var myLayer = document.getElementById(layer);
  if(myLayer.style.display=="none" || myLayer.style.display==""){
    myLayer.style.display="block";
  } else { 
    myLayer.style.display="none";
  }
}

//listen for cntrl-enter to refresh graph viz
//$(function() {
//   $(window).keypress(function(e) {
//      var key = e.which;
      //do stuff with "key" here... Note: id 118 is the 'v'
//      if(key==118){
//        $('#outputer').html(key);
//        window.location.href = '/';
//      }
//   });
//});


//-----------------------------------------


// this is currently a bit of a hack of jQuery and non-jQuery code.
// Not sure how to convert it all into jQuery though...
// Code for adding more input fields modified from http://www.quirksmode.org/dom/domform.html

// global variables
// - "counter" is used to keep track of the input fields generated on-the-fly
// - "selected_node" keeps track of which node is selected for editing
// - "selected_node_properties" contains the properties of the selected node
// - "reserved_keys" is a global constant and keeps track of property names
//   which are reserved for system use
// - "window.buildingarrow" is a boolean that stores if an arrow is currently being created by source and target
// - "window.arrowquery" is used to store the key:value dictionary for a new arrow when buildingarrow
// - "source" is used to store the nodeid of the source node when buildingarrow
// - "target" is used to store the nodeid of the target node when buildingarrow
// - "fullmenu" is the boolean that stores if the full menu is toggled open
var counter = 0;
var selected_arrow;
var selected_arrow_properties;
var selected_node = -1;
var selected_node_properties;
var reserved_keys = ["_id"];
window.arrowquery;
window.buildingarrow = false;
var source = "0";
var target = "0";
var fullmenu = false;

// adds pairs of input fields for properties and values
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

// selects a node for editing
// called either by clicking on a node in the visualisation while the
// "edit node" menu is open or by entering a number into the "select node"
// input field and then clicking the "select node" button
function select_node(nodeid) {
    console.log("Selection of nodeid: ", nodeid, " called.");
    //console.log("Building arrow is: ", buildingarrow);
    
    //console.log("#searchAddNodeField focus is: ", $("#searchAddNodeField").is(":focus"));

    selected_node_properties = {};
    $.post('/get_id', {nodeid: nodeid}, function(data) {
      //Displays the selected node in the Node Info Box
      //Sets selected_node to nodeid;
      //TODO: Highlight the selected node in the mainGraph
      //TODO: Highlight the selected node in the subGraph
      // Sets source to selected nodeid

      if (data == "error") {
          alert("Node with ID " + nodeid + " could not be found.");
      } else {
        selected_node = nodeid;

        //Switches out menus
        $("#nodeKeyValues").show();
        $('#nodeKeyValues').text(JSON.stringify(data));

        $("#syntaxNodeInfo").show();
        name = data['name'];
        descript = data['description'];
        displayedInfo = "Node Name: " + JSON.stringify(name) + "\n Node description: " + JSON.stringify(descript);
        $('#syntaxNodeInfo').text(displayedInfo);
        
        console.log(JSON.stringify(data));
        $('#SelectNodeID').val(selected_node);
        $("#editButtonHolder").show();
        
        $("#queryform").hide();
        cleanup_editable_menu();

        //Creates an arrow if buildingarrow
        if(buildingarrow){
          target=nodeid;
          console.log("Creating an arrow from: ", source, " to ", target);
          SANcreateArrow();
        }
        else{
          source=nodeid;
        }

        //Hide the create node box
         $("#searchAddNodeField").hide();

      };
    });
}

  function cleanup_editable_menu(){
    $("#edit-menu-inputs").hide();
    $(".EditProperty").each(function(i, obj) {
      $(this)[0].parentNode.removeChild($(this)[0]);
    });
  }


          //$("#edit-menu-inputs").css("display", "none");
          /*$(".EditProperty").each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });*/

//Turns selected node data into editable
function edit_node(nodeid){
  console.log("Edit of nodeid: ", nodeid, " called.");

    selected_node_properties = {};
    $.post('/get_id', {nodeid: nodeid}, function(data) {

      if (data == "error") {
          alert("Node with ID " + nodeid + " could not be found.");
      } else {
        $('#SelectNodeID').val(selected_node);
        console.log("Node data: ID " + nodeid + "\n" + JSON.stringify(data));
        if ($("#edit-menu-inputs").css("display") == "none") {
          $("#edit-menu-inputs").css("display", "block");
        } else {
          $('.EditProperty').each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
        };
        for (property in data) {
          selected_node_properties[property] = data[property];
          moreFields("writerootEdit","readrootEdit","EditProperty");
          $("input[name=propertyEdit"+counter+"]").val(property);
          $("input[name=valueEdit"+counter+"]").val(data[property]);
        };
      };
    });
}


// checks whether property names will break the cypher queries or are any of
// the reserved terms
function is_illegal(property, type) {
  if (property == '') { 
    alert(type + " name must not be empty.");
    return true;
  } else if (/^.*[^a-zA-Z0-9_].*$/.test(property)) {
    alert(type + " name '" + property + "' illegal: " + type + " names must only contain alphanumeric characters and underscore.");
    return true;
  } else if (reserved_keys.indexOf(property) != -1) {
    alert(type + " name illegal: '" + property + "' is a reserved term.");
    return true;
  } else {
    return false;
  };
}


// takes a form and populates a propertyObject with the property-value pairs
// contained in it, checking the property names for legality in the process
// returns: submitOK: a boolean indicating whether the property names were all
//                    legal
//          propertyObject: a dictionary of property-value pairs
function assign_properties(form_name) {
    var submitOK = true;
    var propertyObject = {};
    $("." + form_name + "Property").each(function(i, obj) {
      var property = $(this).children(".property" + form_name).val();
      var value = $(this).children(".value" + form_name).val();
      // check whether property name is allowed and ensure that user does not
      // accidentally assign the same property twice
      // - if property name is not ok, there is an apropriate error message and
      //   node creation is cancelled
      // - if property name is ok, property-value pair is assigned to the
      //   nodeObject, escaping any single quotes in the value so they don't
      //   break the cypher query
      if (is_illegal(property, "Property")) {
        submitOK = false;
      } else if (property in propertyObject) {
        alert("Property '" + property + "' already assigned.\nFirst value: " + propertyObject[property] + "\nSecond value: " + value);
        submitOK = false;
      } else {
        propertyObject[property] = value.replace(/'/g, "\\'");
      };
    });
    return [submitOK, propertyObject];
}

//Queries the server to create a node using the data from the searchAddNodeField (SANField)
//If witharrow is TRUE then also creates an arrow from global variables source --> target
//Selects the newly created node
//Resets the SANFields
//Sets source to the id of the newly created node.
function SANcreateNode(amBuildingArrow, readField){
  console.log("SANcreateNode called for query text",$(readField).val());
  $.post('/submit', {"text":$(readField).val()}, function(data) {
    console.log("Selecting Node:", data);
    select_node(data);
    $("#querybox").append('<li>'+$(readField).val()+'</li>');
    $(readField).val("");
    if(amBuildingArrow) {
      console.log("Set target to: ", data);
      target=data;
      SANcreateArrow();
    }
    else{
      console.log("Set source to: ", data);
      source=data;
    }
    //alert("You have created Node: " + data);
    console.log("Redoing the viz");
    redoviz();
  });
}

//Queries the server to create an arrow from global variables source --> target
//Resets the arrowquery text fields and resets building arrow to false.
function SANcreateArrow(){
  console.log("Creating an arrow with source: ", source, " and target: ", target);
  buildingarrow=false;
  $.post('/submitarrow', {"text":arrowquery, "from":source, "to":target}, function(data) { 
    console.log(data);
    $("#arrowquerybox").append('<li>'+arrowquery+'</li>');
    $('#searchAddArrowField').val("");
    //buildingarrow=false;
    $('#searchAddNodeFieldLabel').text("(Source) Node"); 
    alert("You have created arrow " + data + " from source: " + source + " to target: " + target);
    
    redoviz();

    $("#buildTargetArea").hide();
  });
}

//Switches to the interface to allow the creation of a new node
function switchToNodeCreate(){
  $("#edit-menu-inputs").hide();
  $("#nodeKeyValues").hide();
  $("#searchAddNodeField").show();
  $("#searchAddNodeField").focus();
}


// this is the interactive stuff that happens after the document has loaded
$(document).ready(function(){

  //open initial prop/value fields for creating new nodes/arrows
  moreFields("writerootObj","readrootObj","NodeProperty");
  moreFields("writerootArr","readrootArr","ArrProperty");


  /* Tab menu functionality */
  //  Main function that shows and hides the requested tabs and their content
  var set_tab = function(tab_container_id, tab_id){
    //  Remove class "active" from currently active tab
    $('#' + tab_container_id + ' ul li').removeClass('active');

    //  Now add class "active" to the selected/clicked tab
    $('#' + tab_container_id + ' a[rel="'+tab_id+'"]').parent().addClass("active");

    //  Hide contents for all the tabs.
    //  The '_content' part is merged with tab_container_id and the result
    //  is the content container ID.
    //  For example for the original tabs: tab_container_id + '_content' = original_tabs_content
    $('#' + tab_container_id + '_content .tab_content').hide();

    //  Show the selected tab content
    $('#' + tab_container_id + '_content #' + tab_id).show();
  }

  //  Function that gets the hash from URL
  var get_hash = function(){
    if (window.location.hash) {
      //  Get the hash from URL
      var url = window.location.hash;

      //  Remove the #
      var current_hash = url.substring(1);

      //  Split the IDs with comma
      var current_hashes = current_hash.split(",");

      //  Loop over the array and activate the tabs if more then one in URL hash
      $.each(current_hashes, function(i, v){
        set_tab($('a[rel="'+v+'"]').parent().parent().parent().attr('id'), v);
      });
    }
  }

  //  Called when page is first loaded or refreshed
  get_hash();

  //  Looks for changes in the URL hash
  $(window).bind('hashchange', function() {
    get_hash();
  });

  //  Called when we click on the tab itself
  $('.tabs_wrapper ul li').click(function() {
    var tab_id = $(this).children('a').attr('rel');

    //  Update the hash in the url
    window.location.hash = tab_id;

    //  Do nothing when tab is clicked
    return false;
  });
  /* End tab menu functionality */


  // create a new node from the data in the create node input form
  $("#createObj").on("click", function(event){
    var nodeObject;
    // check property names and assign property-value pairs to nodeObject
    // first component of nodeObject is boolean result of whether all
    // properties are legal; second component is dictionary of properties to
    // be assigned
    nodeObject = assign_properties("Node");
    // if all property names were fine, remove the on-the-fly created input
    // fields and submit the data to the server to actually create the node
    if (nodeObject[0]) {
      $('.NodeProperty').each(function(i, obj) {
        $(this)[0].parentNode.removeChild($(this)[0]);
      });
      console.log(JSON.stringify(nodeObject[1]));
      $.post('/create_node', nodeObject[1], function(data) {
        //alert("Created node with ID " + data);
        moreFields("writerootObj","readrootObj","NodeProperty");
        redoviz();
      });
    }
  });

  // creates a relationship from the data in the create-relationship input form
  $("#createArr").on("click", function(event){
    // relationships must have a beginning and end node (given by ID) and a
    // type; beginning and end node IDs must be numbers; relationship type
    // must obey same rules as property names
    // if any of these conditions are not satisfied, the user is informed and
    // relationship creation is cancelled
    if (!(/^[0-9]+$/.test($("#from").val()))) {
      alert("'From: node ID' must be a number.")
      return false;
    };
    if (!(/^[0-9]+$/.test($("#to").val()))) {
      alert("'To: node ID' must be a number.")
      return false;
    };
    if (is_illegal($("#rel-type").val(), "Relationship type")) {
      return false;
    };
    var relObject = {from: $("#from").val(),
                     to: $("#to").val(),
                     type: $("#rel-type").val()};
    var relProperties;
    // check property names and assign property-value pairs
    // first component of relProperties is boolean result of whether all
    // properties are legal; second component is dictionary of properties to
    // be assigned
    relProperties = assign_properties("Arr");
    // if all is well, send data to server
    if (relProperties[0]) {
      relObject["properties"] = relProperties[1];
      console.log(JSON.stringify(relObject));
      $.post('/create_rel', relObject, function(data) {
        if (data == "error") {
          // most likely cause for errors is trying to create a relationship
          // where one of the end nodes does not exist
          alert("An error occured. Please check whether nodes with the given IDs (" + $("#from").val() + ", " + $("#to").val() + ") exist.");
        } else {
          // if relationship has been created successfully, remove the on-the-
          // fly generated input fields
          $('.ArrProperty').each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
          //alert("Created relationship with ID " + data + ".");
          redoviz();
        };
      });
    }
  });


  // selects a node for editing from the node ID input field
  $("#SelectNodeForm").on("submit",function(event) {
    event.preventDefault();
    // check whether node ID is a number
    if (!(/^[0-9]+$/.test($("#SelectNodeID").val()))) {
      alert("Node ID must be a number.");
    } else {
      select_node($("#SelectNodeID").val());
      edit_node($("#SelectNodeID").val());
    };
  });


  // Edits properties of a node
  $("#EditNode").on("click", function(event){
    var nodeObject;
    // assign property-value pairs to nodeObject and check for legality
    // first component of nodeObject is boolean result of whether all
    // properties are legal; second component is dictionary of properties to
    // be assigned
    nodeObject = assign_properties("Edit");
    if (nodeObject[0]) {
      // check which properties have changed and which ones are being deleted
      var deleted_props = [];
      for (var property in selected_node_properties) {
        if (property in nodeObject[1]) {
          if (selected_node_properties[property] === nodeObject[1][property]) {
            // don't have to re-set property value if it hasn't changed
            delete nodeObject[1][property];
          };
        } else {
          // this is a list of properties that are being deleted
          deleted_props.push(property);
        };
      };
      // ask for confirmation before deleting properties
      // (two different messages in the interest of grammar)
      if (((deleted_props.length == 1) && (!(confirm("Are you sure you want to delete the following property? " + deleted_props)))) || ((deleted_props.length > 1) && (!(confirm("Are you sure you want to delete the following properties? " + deleted_props))))) {
        alert("Cancelled saving of node " + selected_node + ".");
        return false;
      };
      // do not make a server request if the node hasn't changed
      if ((JSON.stringify(nodeObject[1]) === "{}") && (deleted_props.length == 0)) {
        alert("Node " + selected_node + " has not changed and does not need to be saved.");
        return false;
      };
      console.log(JSON.stringify(nodeObject[1]));
      $.post('/edit_node', {nodeid: selected_node, properties: nodeObject[1], remove: deleted_props}, function(data) {
        if (data === "error") {
          alert("Failed to save changes to node " + selected_node + ".");
        } else {
          alert("Saved changes to node " + selected_node + ".");
          redoviz();
          //$("#edit-menu-inputs").css("display", "none");
          /*$(".EditProperty").each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });*/
        };
      });
    };
  });


  // Deletes a node after checking for user confirmation
  // (delete button is right next to save, after all)
  $("#DeleteNode").on("click", function(event){
    if (confirm("Are you sure you want to delete node " + selected_node + "?")) {
      $.post('/delete_node', {nodeid: selected_node}, function(data) {
        if (data === "error") {
          alert("Could not delete node " + selected_node + ". Ensure you delete all relationships involving a node before deleting the node itself.");
        } else {
          //alert("Deleted node " + selected_node + ".");
          $("#edit-menu-inputs").css("display", "none");
          $(".EditProperty").each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
          $("#stopeEditButtonHolder").hide();
          redoviz();
        }
      });
    };
  });

  // selects an arrow for editing from the arrow ID input field
  $("#SelectArrowForm").on("submit",function(event) {
    event.preventDefault();
    // check whether arrow ID is a number
    if (!(/^[0-9]+$/.test($("#SelectArrowID").val()))) {
      alert("Arrow ID must be a number.");
    } else {
    selected_arrow_properties = {};
    $.post('/get_arrow', {id: $("#SelectArrowID").val()}, function(data) {
      if (data == "error") {
          alert("Arrow with ID " + $("#SelectArrowID").val() + " could not be found.");
      } else {
        selected_arrow = $("#SelectArrowID").val();
        console.log("Arrow data: ID " + $("#SelectArrowID").val() + "\n" + JSON.stringify(data));
        if ($("#edit-arrow-menu-inputs").css("display") == "none") {
          $("#edit-arrow-menu-inputs").css("display", "block");
        } else {
          $('.EditArrowProperty').each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
        };
        $("#edit-from").html("from: " + data.from);
        $("#edit-to").html("to: " +data.to);
        $("#edit-rel-type").html("type: " + data.type);
        for (property in data.properties) {
          selected_arrow_properties[property] = data.properties[property];
          moreFields("writerootEditArrow","readrootEditArrow","EditArrowProperty");
          $("input[name=propertyEditArrow"+counter+"]").val(property);
          $("input[name=valueEditArrow"+counter+"]").val(data.properties[property]);
        };
      };
    });
    };
  });


  // Edits properties of an arrow
  $("#EditArrow").on("click", function(event){
    var relObject;
    // assign property-value pairs to relObject and check for legality
    // first component of relProperties is boolean result of whether all
    // properties are legal; second component is dictionary of properties to
    // be assigned
    relObject = assign_properties("EditArrow");
    if (relObject[0]) {
      // check which properties have changed and which ones are being deleted
      var deleted_props = [];
      for (var property in selected_arrow_properties) {
        if (property in relObject[1]) {
          if (selected_arrow_properties[property] === relObject[1][property]) {
            // don't have to re-set property value if it hasn't changed
            delete relObject[1][property];
          };
        } else {
          // this is a list of properties that are being deleted
          deleted_props.push(property);
        };
      };
      // ask for confirmation before deleting properties
      // (two different messages in the interest of grammar)
      if (((deleted_props.length == 1) && (!(confirm("Are you sure you want to delete the following property? " + deleted_props)))) || ((deleted_props.length > 1) && (!(confirm("Are you sure you want to delete the following properties? " + deleted_props))))) {
        alert("Cancelled saving of arrow " + selected_arrow + ".");
        return false;
      };
      // do not make a server request if the arrow hasn't changed
      if ((JSON.stringify(relObject[1]) === "{}") && (deleted_props.length == 0)) {
        alert("Arrow " + selected_arrow + " has not changed and does not need to be saved.");
        return false;
      };
      console.log(JSON.stringify(relObject[1]));
      $.post('/edit_arrow', {id: selected_arrow, properties: relObject[1], remove: deleted_props}, function(data) {
        if (data === "error") {
          alert("Failed to save changes to arrow " + selected_arrow + ".");
        } else {
          alert("Saved changes to arrow " + selected_arrow + ".");
          $("#edit-arrow-menu-inputs").css("display", "none");
          $(".EditArrowProperty").each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
          redoviz();
        };
      });
    };
  });


  // Deletes an arrow after checking for user confirmation
  // (delete button is right next to save, after all)
  $("#DeleteArrow").on("click", function(event){
    if (confirm("Are you sure you want to delete arrow " + selected_arrow + "?")) {
      $.post('/delete_arrow', {id: selected_arrow}, function(data) {
        if (data === "error") {
          alert("Could not delete arrow " + selected_arrow + ".");
        } else {
          alert("Deleted arrow " + selected_arrow + ".");
          $("#edit-arrow-menu-inputs").css("display", "none");
          $(".EditArrowProperty").each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
          redoviz();
        }
      });
    };
  });

  //Parses searchAddNodeField input into a dictionary of properties to create a node on click
  $("#queryform").on("click", function(event){
    SANcreateNode(buildingarrow,'#searchAddNodeField');
    console.log("building arrow ", buildingarrow);
  });

  //Parses searchAddNodeField input into a dictionary of properties
  $('#searchAddNodeField').keydown(function(e) {
    var code = e.keyCode || e.which;
    //console.log(code);
    
    //If ENTER or TAB then queries the server to create a node
    if(code == 13 || code == 9) { //Enter keycode
      e.preventDefault();  

      SANcreateNode(buildingarrow, '#searchAddNodeField');

      //If TAB or switches focus to searchAddArrowField
      if(code == 9){
        //$("#searchAddArrowField").show();
        $("#searchAddArrowField").focus();    
      }
    }
  });

  //Parses searchAddArrowField Query 
  //ENTER or TAB stores the input properties for an arrow in variable arrowquery and marks buildingarrow=true
  $('#searchAddArrowField').keydown(function(e){
    var code = e.keyCode || e.which;
    if(code == 13 || code == 9) {
      e.preventDefault();  
      console.log("searchAddArrowField query made with text: ", $("#searchAddArrowField").val());
      window.arrowquery = $("#searchAddArrowField").val();
      $('#searchAddArrowField').val("");
      buildingarrow=true;
      $("#buildTargetAreaField").focus();     
    }
  });

  $("#searchAddArrowField").focus(function (){
    $("#buildTargetArea").show();
  });

  $("#searchAddArrowField").focusout(function (){
    if(!$("#buildTargetAreaField").is(":visible"))
      $("#buildTargetArea").hide();
  });
  
  //Parses buildTargetAreaField input into a dictionary of properties to create a node on click
  $("#targetQueryForm").on("click", function(event){
    SANcreateNode(buildingarrow,'#buildTargetAreaField');
    console.log("building arrow ", buildingarrow);
  });

  //Parses buildTargetAreaField input into a dictionary of properties
  $('#buildTargetAreaField').keydown(function(e) {
    var code = e.keyCode || e.which;
    //console.log(code);
    
    //If ENTER or TAB then queries the server to create a node
    if(code == 13 || code == 9) { //Enter keycode
      e.preventDefault();  

      SANcreateNode(buildingarrow,'#buildTargetAreaField');

      //If TAB or switches focus to buildTargetAreaField
      if(code == 9){
        //$("#searchAddArrowField").show();
        $("#searchAddArrowField").focus();    
      }
    }
  });

  //On click of createNodeButton focuses on searchAddNodeField
  $("#createNodeButton").on("click", function(event){
    switchToNodeCreate();
  });

  //On click of createArrowButton focuses on searchAddNodeField
  $("#createArrowButton").on("click", function(event){
    if(selected_node==-1){
      alert("First select a Node to be your new arrow's source.")
    }
    else{
      $("#searchAddArrowField").focus();
    }
  });

  //TAB focuses on searchAddArrowField unless buildingarrow
  //ENTER hits addNode button
  $(function() {
     $(window).keydown(function(e) {
        var code = e.keyCode || e.which;
        //console.log(code, buildingarrow);
        if((code == 9) && (window.location.hash == "#syntax")) {
          e.preventDefault(); 
          if(!buildingarrow){
            $("#searchAddArrowField").focus();
          }
        }
        else if(code==13){
          e.preventDefault(); 
          if(!buildingarrow){
            switchToNodeCreate();
          }
        }
     });
  });

  //On click of editNodeButton changes selected node data to make fields editable
  $("#editNodeButton").on("click", function(event){
    window.location.hash = "#edit";
    edit_node(selected_node);
  });

  //Turns off node editing menu with stopeEditNodeButton
  $("#stopeEditNodeButton").on("click", function(event){
    $("#nodeKeyValues").show();
    $("#editButtonHolder").show();
    
    select_node(selected_node);
    $("#queryform").show();
    $("#stopeEditButtonHolder").hide();
  });

  //SETS UP THE TYPEAHEAD get node box
  $.getJSON('/node_names', function(data){
      console.log("get names called");

      var n, namesList;

      namesList = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          n = data[_i];
          _results.push(n['name']);
        }
        return _results;
      })();

      console.log(namesList);

      $("#searchBox").typeahead({
        name: 'thenodes',
        local: namesList,
        limit: 10 //NOTE THIS IS A #HACK
      });

      //On click of #getNode focuses on searchAddNodeField
      $("#getNode").on("click", function(event){
        nodename= $("#searchBox").val();
        
        var n, searchedNodeID, _i, _len;

        for (_i = 0, _len = data.length; _i < _len; _i++) {
          n = data[_i];
          if (n["name"] === nodename) {
            searchedNodeID = n["_id"];
          }
        }

        select_node(searchedNodeID);

      });

    }
  )

  //Selects a Node with the search bar
  //Does not yet work due to the bad numbering of the graph JSON object
  /*$("#searchBox").on("submit", function(event){
    $("#nodeKeyValues").show();
    $("#editButtonHolder").show();
    select_node(selected_node);
    $("#stopeEditButtonHolder").hide();
  });*/

});
