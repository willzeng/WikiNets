define ["core/singleton", "core/graphView", "core/workspace"], (Singleton, GraphView, Workspace) ->

  class ForceSlidersView extends Backbone.View

    constructor: (@force) ->
      super()

    render: () ->
      $container = $ """
        <div class="force-sliders-container">
          <table border="0">
            <tr><td class="slider-label">Charge: </td><td><input id="input-charge" type="range" min="0" max="100"></td></tr>
            <tr><td class="slider-label">Gravity: </td><td><input id="input-gravity" type="range" min="0" max="100"></td></tr>
          </table>
        </div>
      """
      $container.appendTo @$el

      ###
      An attempt at a DRY way of linking the force layout parameters to the DOM. For each parameter, these are expected:

      - `f` - the getter/setter function for a particular force layout parameter
      - `selector` - the selector of the slider for that force layout parameter
      - `scale` - the scale mapping value within the force layout to the values used by the slider in the DOM

      So define these mappings for each parameter then hook 'em up to the DOM.

      ###

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
      ]

      _.each mappings, (mapping) =>
        force = @force # sorry - need `this` to be the DOM element below
        @$(mapping.selector).val(mapping.scale(mapping.f())).change ->
          mapping.f mapping.scale.invert($(this).val()) # <== here
          $(this).blur()
          force.start()
      return this

  class ForceSlidersAPI extends Backbone.Model
    constructor: () ->
      force = GraphView.getInstance().getForceLayout()
      linkFilter = GraphView.getInstance().getLinkFilter()
      view = new ForceSlidersView(force, linkFilter).render()
      Workspace.getInstance().addTopLeft(view.el);

  _.extend ForceSlidersAPI, Singleton
