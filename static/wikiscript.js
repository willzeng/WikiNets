function showlayer(layer){
  var myLayer = document.getElementById(layer);
  if(myLayer.style.display=="none" || myLayer.style.display==""){
    myLayer.style.display="block";
  } else { 
    myLayer.style.display="none";
  }
}


//-----------------------------------------


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


$(document).ready(function(){

  // there should probably be a more elegant way of doing all of this
  // menu showing/hiding, but I haven't figured it out yet.
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


  $("#createObj").on("click", function(event){
    var nodeObject = {};
    var submitOK = true;
    $('.nodeProperty').each(function(i, obj) {
      var property = $(this).children(".propertyObj").val();
      var value = $(this).children(".valueObj").val();
      if (/^.*[^a-zA-Z0-9_-].*$/.test(property)) {
        alert("Property name '" + property + "' illegal:\nproperty names must only contain alphanumeric characters,\nunderscore and dash.");
        submitOK = false;
        return false;
      } else {
        if (property in nodeObject) {
          alert("Property '" + property + "' already assigned.\nFirst value: " + nodeObject[property] + "\nSecond value: " + value);
          submitOK = false;
          return false;
        } else {
          nodeObject[property] = value;
        };
      };
    });
    if (submitOK) {
      $('.nodeProperty').each(function(i, obj) {
        $(this)[0].parentNode.removeChild($(this)[0]);
      });
      console.log(JSON.stringify(nodeObject));
      $.post('/create_node', nodeObject, function(data) {
        alert("Created node with ID " + data);
        // would now like to reload the visualisation here
      });
    }
  });
 
});
