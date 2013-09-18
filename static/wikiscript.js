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
    $('.nodeProperty').each(function(i, obj) {
      var property = $(this).children(".propertyObj").val();
      var value = $(this).children(".valueObj").val();
      // should really do some input validation here:
      // currently, if the same property is assigned twice, the value is just overwritten
      // also might want to look out for security issues -- but I don't know what to look out for
      nodeObject[property] = value;
      $(this)[0].parentNode.removeChild($(this)[0]);
    });
    console.log(JSON.stringify(nodeObject));
    $.post('/create_node', nodeObject, function(data) {
      // this forces a reload of the entire page to update the data
      // should be replaced by Erfan's stuff for updating only bits
      // once he's got that working
      //window.location.reload();
      alert("Created node with ID " + data);
    });
  });
 
});
