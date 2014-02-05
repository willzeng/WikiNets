# provides details and editing functionality for the selected links
define [], () ->

  class LinkEdit extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      
      #require plugins
      @dataController = instances['local/Neo4jDataController']

      @graphModel = instances['GraphModel']
      @graphModel.on "change", @update.bind(this)

      @selection = instances["LinkSelection"]
      @selection.on "change", @update.bind(this)
      @listenTo instances["KeyListener"], "down:16:80", () => @$el.toggle()
      instances["Layout"].addPlugin @el, @options.pluginOrder, 'Link Edit', true

      @Create = instances['local/Create']

    update: ->
      @$el.empty()
      selectedLinks = @selection.getSelectedLinks()
      $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
      blacklist = ["selected", "source", "target", "strength"]
      # not sure whether "strength" should be in the blacklist or not...?
      _.each selectedLinks, (link) =>
        $linkDiv = $("<div class=\"node-profile\"/>").appendTo($container)
        header = @findHeader(link)
        $("<div class=\"node-profile-title\">#{header}</div>").appendTo $linkDiv
        _.each link, (value, property) ->
          console.log value, property
          value += ""
          if blacklist.indexOf(property) < 0
            if value?
              makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi,"<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>")
            else
              makeLinks = value
            $("<div class=\"node-profile-property\">#{property}: #{makeLinks}</div>").appendTo $linkDiv

    findHeader: (link) ->
      # header should be of form "(startnode) -TYPE- (endnode)"
      if link.type?
        link.type
      else if link.name?
        link.name
      else
        '--'
