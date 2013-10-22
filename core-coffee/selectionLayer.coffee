define ['jquery', 'underscore', 'backbone', 'd3'], ($, _, Backbone, d3) ->
    class SelectionLayer
        constructor: (args) ->
            @parent = args.parent
            @$parent = $(@parent)
            _.extend this, Backbone.Events
            @_intializeDragVariables()
            @render()

        render: =>
            @canvas = $('<canvas/>').addClass('selectionLayer')
                                    .css('position', 'absolute')
                                    .attr('width', $('body').width())
                                    .attr('height', $('body').height())
                                    .css('top', 0)
                                    .css('left', 0)
                                    .css('margin', '8px')
                                    .css('pointer-events', 'none')[0]

            @$parent.append @canvas
            @_registerMouseEvents()

        _intializeDragVariables: =>
            @dragging = false
            @startPoint =
                x: 0
                y: 0
            @prevPoint =
                x: 0
                y: 0
            @currentPoint =
                x: 0
                y: 0

        _setStartPoint: (coord) =>
            @startPoint.x = coord.x
            @startPoint.y = coord.y

        _registerMouseEvents: =>
            @$parent.mousedown (e) =>
                if e.shiftKey
                    @dragging = true;
                    _.extend @startPoint, {
                        x: e.pageX
                        y: e.pageY
                    }
                    return false;

            @$parent.mousemove (e) =>
                if e.shiftKey
                    if @dragging
                        _.extend @prevPoint, @currentPoint
                        _.extend @currentPoint, {
                            x: e.pageX
                            y: e.pageY
                        }
                        @renderRect()
                        return false;

            @$parent.mouseup (e) =>
                @dragging = false
                @_clearRect @startPoint, @currentPoint
                _.extend @startPoint, {
                    x: 0
                    y: 0
                }
                _.extend @currentPoint, {
                    x: 0
                    y: 0
                }

            $(window).keyup (e) =>
                if e.keyCode == 16
                    @dragging = false
                    @_clearRect @startPoint, @prevPoint
                    @_clearRect @startPoint, @currentPoint

        renderRect: =>
            @_clearRect @startPoint, @prevPoint
            @_drawRect @startPoint, @currentPoint

        rectDim: (startPoint, endPoint) =>
            dim = {}
            dim.x = if startPoint.x < endPoint.x then startPoint.x else endPoint.x
            dim.y = if startPoint.y < endPoint.y then startPoint.y else endPoint.y
            dim.width = Math.abs(startPoint.x - endPoint.x)
            dim.height = Math.abs(startPoint.y - endPoint.y)
            return dim

        _drawRect: (startPoint, endPoint) =>
            dim = @rectDim startPoint, endPoint
            ctx = @canvas.getContext '2d'
            ctx.fillStyle = 'rgba(255, 255, 0, 0.2)'
            ctx.fillRect dim.x, dim.y, dim.width, dim.height

        _clearRect: (startPoint, endPoint) =>
            dim = @rectDim startPoint, endPoint
            ctx = @canvas.getContext '2d'
            ctx.clearRect dim.x, dim.y, dim.width, dim.height
