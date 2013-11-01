## API

## Code

    define ["core/singleton"], (Singleton) ->

      class Workspace extends Backbone.View
        render: ->
          @tl = $("<div id=\"top-left-container\" class=\"container\"/>")
          @bl = $("<div id=\"bottom-left-container\" class=\"container\"/>")
          @br = $("<div id=\"bottom-right-container\" class=\"container\"/>")
          @tr = $("<div id=\"top-right-container\" class=\"container\"/>")
          @$el.append(@tl).append(@bl).append(@br).append(@tr)
          return this

      class WorkspaceAPI extends Backbone.Model
        constructor: (options) ->
          @workspace = new Workspace(options).render()
        addCenter: (el) ->
          @workspace.$el.append el
        addTopLeft: (el) ->
          @workspace.tl.append el
        addBottomLeft: (el) ->
          @workspace.bl.append el
        addTopRight: (el) ->
          @workspace.tr.append el
        addBottomRight: (el) ->
          @workspace.br.append el

      _.extend WorkspaceAPI, Singleton
