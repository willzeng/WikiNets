# provides details of the selected nodes
define [], () ->

  class NodeTagFilter extends Backbone.View

    constructor: (@options) ->
      @parent = ""
      @parent ?= @options.parent
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @dataProvider = instances["local/WikiNetsDataProvider"]
      
      @parent = $("#buildbar")

      @render()

      @$el.appendTo @parent

    render: ->
      $container = $("<div id=\"node-filter-box\" data-intro='Click Themes to see projects' data-position='left'>View by theme</div>")
        .css("width", "160px")
        .css("padding", "7px")
        .css("background-color", "white")
        .css("border", "1px solid gray")
      $container.appendTo @$el

      @$el.css("position","absolute")
        .css("top","30px")
        .css("right","10px")

      themesList = ["Research", "Learning", "Student Life", "Other"]

      `for(var k=0;k<themesList.length;k++){
          (function(theme, _this){
            themeButton = $("<div><input type=\"button\" class=\"theme-button\" value=\""+theme+"\"></input></div>").appendTo($container)
            $(themeButton).click(function(){
              _this.searchNodes({'Theme':theme});
              });
            })(themesList[k], this)
        }`

      $showAllButton = $("<div><input type=\"button\" class=\"theme-button\" value=\"Show All Themes\"></input></div>").appendTo $container
      $showAllButton.click () =>
        @dataProvider.getDefault(@loadAllNodes)

      $clearAllButton = $("<div><input type=\"button\" class=\"theme-button\" value=\"Clear All\"></input></div>").appendTo $container
      $clearAllButton.click () =>
        @graphModel.filterNodes (node) -> false    
        
      # this shouldn't really be in this module, but it's easiest to just add it here for now
      $keyContainer = $("<div id=\"key-box\" data-position='left'>Key to node colours:</div>")
        .css("margin-top", "10px")
        .css("width", "160px")
        .css("padding", "7px")
        .css("background-color", "white")
        .css("border", "1px solid gray")
        .css("font-size", "12px")
      $keyContainer.appendTo @$el
      # should replace colour squares with svg circles
      $("<ul style=\"list-style-type:none;\"><li><svg width=\"12\" height=\"12\"><circle cx=\"6\" cy=\"6\" r=\"5\" stroke=\"#a9a9a9\" stroke-width=\"2\" fill=\"white\"/></svg> Submitted</li><li><svg width=\"12\" height=\"12\"><circle cx=\"6\" cy=\"6\" r=\"5\" stroke=\"#2f435a\" stroke-width=\"2\" fill=\"white\"/></svg> Qualified</li><li><svg width=\"12\" height=\"12\"><circle cx=\"6\" cy=\"6\" r=\"5\" stroke=\"#e85e12\" stroke-width=\"2\" fill=\"white\"/></svg> Selected</li></ul>").appendTo $keyContainer
      $("<span>The size of each node represents the number of votes the idea has received.</span>").appendTo $keyContainer

    loadAllNodes: (nodes) =>
      @graphModel.putNode node for node in nodes

    searchNodes: (searchQuery) =>
      $.post "/search_nodes", searchQuery, (nodes) =>
        @graphModel.filterNodes (node) -> false
        for node in nodes
          @graphModel.putNode(node)

