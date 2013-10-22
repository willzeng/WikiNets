define ["jquery", "underscore", "backbone"], ($, _, Backbone) ->
    Backbone.View.extend
        initialize: (options) ->
            @selection = options.selection
            @selection.on "change", @update.bind(this)

        render: ->
            this

        update: ->
            @$el.empty()
            selectedNodes = @selection.getSelectedNodes()
            $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
            blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
            _.each selectedNodes, (node) ->
                $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
                $("<div class=\"node-profile-title\">" + node["text"] + "</div>").appendTo $nodeDiv
                _.each node, (value, property) ->
                    $("<div class=\"node-profile-property\">" + property + ":  " + value + "</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0



        toggle: ->
            @$el.toggle()

