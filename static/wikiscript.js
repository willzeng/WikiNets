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
var counter = 0;
var selected_node;
var selected_node_properties;
var reserved_keys = ["_id"];

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
    selected_node_properties = {};
    $.post('/get_id', {nodeid: nodeid}, function(data) {
      if (data == "error") {
          alert("Node with ID " + nodeid + " could not be found.");
      } else {
        selected_node = nodeid;
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

// this is the interactive stuff that happens after the document has loaded
$(document).ready(function(){

  // showing or hiding various menus and submenus
  $("img.choose_menu").click(function() {
    showlayer('browse_menu');
    showlayer('edit_menu');
  });
  $("#toggle_en_1").click(function(a) {
    a.preventDefault();
    showlayer('en_1');
  });
  $("#toggle_enn_1").click(function(a) {
    a.preventDefault();
    showlayer('enn_1');
  });
  $("#toggle_sm_1").click(function(a) {
    a.preventDefault();
    showlayer('sm_1');
  });
  $("#toggle_sm_2").click(function(a) {
    a.preventDefault();
    showlayer('sm_2');
  });
  $("#toggle_sm_3").click(function(a) {
    a.preventDefault();
    showlayer('sm_3');
  });

  // create a new node from the data in the create node input form
  $("#createObj").on("click", function(event){
    var submitOK, nodeObject;
    // check property names and assign property-value pairs to nodeObject
    [submitOK, nodeObject] = assign_properties("Node");
    // if all property names were fine, remove the on-the-fly created input
    // fields and submit the data to the server to actually create the node
    if (submitOK) {
      $('.NodeProperty').each(function(i, obj) {
        $(this)[0].parentNode.removeChild($(this)[0]);
      });
      console.log(JSON.stringify(nodeObject));
      $.post('/create_node', nodeObject, function(data) {
        alert("Created node with ID " + data);
        // would now like to have option of reloading the visualisation here
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
    var submitOK, relProperties;
    // check property names and assign property-value pairs to relProperties
    [submitOK, relProperties] = assign_properties("Arr");
    // if all is well, send data to server
    if (submitOK) {
      relObject["properties"] = relProperties;
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
          alert("Created relationship with ID " + data + ".");
          // would now like option to reload the visualisation here
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
    };
  });


  // Edits properties of a node
  $("#EditNode").on("click", function(event){
    var submitOK, nodeObject;
    // assign property-value pairs to nodeObject and check for legality
    [submitOK, nodeObject] = assign_properties("Edit");
    if (submitOK) {
      // check which properties have changed and which ones are being deleted
      var deleted_props = [];
      for (var property in selected_node_properties) {
        if (property in nodeObject) {
          if (selected_node_properties[property] === nodeObject[property]) {
            // don't have to re-set property value if it hasn't changed
            delete nodeObject[property];
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
      if (JSON.stringify(nodeObject) === "{}") {
        alert("Node " + selected_node + " has not changed and does not need to be saved.");
        return false;
      };
      console.log(JSON.stringify(nodeObject));
      $.post('/edit_node', {nodeid: selected_node, properties: nodeObject, remove: deleted_props}, function(data) {
        if (data === "error") {
          alert("Failed to save changes to node " + selected_node + ".");
        } else {
          alert("Saved changes to node " + selected_node + ".");
          $(".EditProperty").each(function(i, obj) {
            $(this)[0].parentNode.removeChild($(this)[0]);
          });
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
          alert("Deleted node " + selected_node + ".");
        }
      });
    };
  });

});
