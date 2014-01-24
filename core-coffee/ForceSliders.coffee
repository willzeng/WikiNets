# includes a spacing slider to adjust the charge in the force directed layout
define [], () ->
  class ForceSliders
    init: (instances) ->
      scale = d3.scale.linear()
        .domain([-20, -6000])
        .range([0, 100])
      force = instances["GraphView"].getForceLayout()
      instances["Sliders"].addSlider "Spacing", scale(force.charge()), (val) ->
        force.charge scale.invert val
        force.start()
