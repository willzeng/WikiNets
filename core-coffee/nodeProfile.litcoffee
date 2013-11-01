## API

## Code

    define ["core/selection", "core/workspace", "core/singleton"], (Selection, Workspace, Singleton) ->

      class NodeProfileView extends Backbone.View

        constructor: (@selection) ->
          @selection.on "change", @update.bind(this)
          super()

        render: ->
          return this

        update: ->
          @$el.empty()
          selectedNodes = @selection.getSelectedNodes()
          $container = $("<div class=\"node-profile-helper\"/>").appendTo(@$el)
          blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"]
          _.each selectedNodes, (node) ->
            $nodeDiv = $("<div class=\"node-profile\"/>").appendTo($container)
            $("<div class=\"node-profile-title\">#{node['text']}</div>").appendTo $nodeDiv
            _.each node, (value, property) ->
              $("<div class=\"node-profile-property\">#{property}:  #{value}</div>").appendTo $nodeDiv  if blacklist.indexOf(property) < 0

        toggle: ->
          @$el.toggle()

      class NodeProfileAPI extends Backbone.Model
        constructor: () ->
          selection = Selection.getInstance()
          view = new NodeProfileView(selection).render()
          workspace = Workspace.getInstance()
          workspace.addBottomRight view.el

      _.extend NodeProfileAPI, Singleton
