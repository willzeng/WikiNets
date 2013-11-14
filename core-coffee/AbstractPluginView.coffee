define [], () ->
    class AbstractPluginView extends Backbone.View

        init: () ->
            console.log 'init!'
            @$el.addClass('plugin-view')

        show: () ->
            console.log 'showing plugin view!!!'

        hide: () ->
            console.log 'hiding plugin view!!!'