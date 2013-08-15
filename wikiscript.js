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