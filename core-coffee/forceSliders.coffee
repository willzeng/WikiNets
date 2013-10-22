define ["jquery", "underscore", "backbone"], ($, _, Backbone) ->
    Backbone.View.extend
        initialize: (options) ->
            @force = options.graphView.getForceLayout()
            @linkFilter = options.linkFilter

        render: ->
            $container = $("<div class=\"force-sliders-container\" />").appendTo(@$el)
            $table = $("<table border=\"0\" />").appendTo($container)
            $("<tr><td class=\"slider-label\">Charge: </td><td><input id=\"input-charge\" type=\"range\" min=\"0\" max=\"100\"></td></tr>").appendTo $table
            $("<tr><td class=\"slider-label\">Gravity: </td><td><input id=\"input-gravity\" type=\"range\" min=\"0\" max=\"100\"></td></tr>").appendTo $table
            $("<tr><td class=\"slider-label\">Connectivity: </td><td><input id=\"input-connectivity\" type=\"range\" min=\"0\" max=\"100\"></td></tr>").appendTo $table

            # define mappings between values in code and values in UI
            mappings = [
                f: @force.charge
                selector: "#input-charge"
                scale: d3.scale.linear()
                               .domain([-20, -2000])
                               .range([0, 100])
            ,
                f: @force.gravity
                selector: "#input-gravity"
                scale: d3.scale.linear()
                               .domain([0.01, 0.5])
                               .range([0, 100])
            ,
                f: @linkFilter.connectivity.bind(@linkFilter)
                selector: "#input-connectivity"
                scale: d3.scale.linear()
                               .domain([1, @linkFilter.get("minThreshold")])
                               .range([0, 100])
            ]

            # hook mappings up to respond to user input
            _.each mappings, (mapping) =>
                force = @force # sorry - need this to be a DOM element below
                @$(mapping.selector).val(mapping.scale(mapping.f())).change ->
                    mapping.f mapping.scale.invert($(this).val()) # <== here
                    force.start()

            return this
