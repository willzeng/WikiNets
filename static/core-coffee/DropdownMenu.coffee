# provides details of the selected nodes
define [], () ->

  class DropdownMenu extends Backbone.View

    constructor: (@options) ->
      @parent = ""
      @parent ?= @options.parent
      super()

    init: (instances) ->
      @graphModel = instances["GraphModel"]
      @dataProvider = instances["local/WikiNetsDataProvider"]
      
      @parent = $("#menuButton")

      @render()

      @$el.appendTo @parent

      @parent.click () =>
        @$el.toggle()        

      @$el.toggle()

    render: ->
      $bbar = $("<div id=\"bbar\"></div>")
        .css("background-color","#979985")
        .css("width","10px")
        .css("height", "110px")
        .appendTo @$el
      $container = $("<div id=\"dropdownMenu\"></div>")
        .css("position","absolute")
        .css("top","40px")
        .css("margin", "7px")
        .css("width", "160px")
        .css("padding", "7px")
        .css("background-color", "white")
        .css("border", "1px solid gray")
      $container.appendTo @$el

      $about = $("<div class=\"dropdownMenuItem\"> <a href=\"http://wikinets.co.uk\" target='_blank'> About </a></div>")
        .css("margin","5px")
        .css("font-size", "16px")
      $about.appendTo $container

      $clearAllButton = $("<div><input type=\"button\" id=\"clearAllButtonDropdown\" value=\"Clear All\"></input></div>").appendTo $container
      $clearAllButton.click(() =>
        @graphModel.filterNodes (node) -> false
        )  

      $showAllButton = $("<input type=\"button\" id=\"showAllButtonDropdown\" value=\"Show All\"></input>").appendTo $container
      $showAllButton.click(() =>
        @dataProvider.getEverything(@loadAllNodes)
        )

    loadAllNodes: (nodes) =>
      @graphModel.putNode node for node in nodes
