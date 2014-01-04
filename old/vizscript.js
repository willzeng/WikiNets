// get size of viewport on load
// might want to make this dynamic at some point?
var viewportwidth;
var viewportheight;
if (typeof window.innerWidth != 'undefined') {
  // Standards compliant browsers (mozilla/netscape/opera/IE7)
  viewportwidth = window.innerWidth,
  viewportheight = window.innerHeight
} else if (typeof document.documentElement != 'undefined'
           && typeof document.documentElement.clientWidth !=
           'undefined' && document.documentElement.clientWidth != 0) {
  // IE6
  viewportwidth = document.documentElement.clientWidth,
  viewportheight = document.documentElement.clientHeight
} else {
  // Older IE
  viewportwidth = document.getElementsByTagName('body')[0].clientWidth,
  viewportheight = document.getElementsByTagName('body')[0].clientHeight
}

/* the size of the graph and subgraph; also used as scaling factors */
var width = viewportwidth-360,
    height = viewportheight-60;
    subwidth=300;
    subheight=300;

/* This variable holds the graph data: an array of links and an array of nodes
   as provided by the server upon an AJAX call to "/json" -- see below */

var graph;

redoviz();
