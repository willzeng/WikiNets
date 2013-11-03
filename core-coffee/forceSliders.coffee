# includes a spacing slider to adjust the charge in the force directed layout
define ["core/singleton", "core/graphView", "core/sliders"],
(Singleton, GraphView, Sliders) ->

  class ForceSliders
    constructor: (force, sliders) ->
      scale = d3.scale.linear()
        .domain([-20, -2000])
        .range([0, 100])
      sliders.addSlider "Spacing", scale(force.charge()), (val) ->
        force.charge scale.invert val
        force.start()

  class ForceSlidersAPI extends ForceSliders
    constructor: () ->
      force = GraphView.getInstance().getForceLayout()
      sliders = Sliders.getInstance()
      super(force, sliders)

  _.extend ForceSlidersAPI, Singleton
