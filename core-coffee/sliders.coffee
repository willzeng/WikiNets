define ["core/singleton", "core/workspace"], (Singleton, Workspace) ->

  class SlidersView extends Backbone.View

    render: () ->
      $container = $ """
        <div class="sliders-container">
          <table border="0">
          </table>
        </div>
      """
      $container.appendTo @$el
      return this

    addSlider: (label, initialValue, onChange) ->

      $row = $ """
        <tr>
          <td class="slider-label">#{label}: </td>
          <td><input type="range" min="0" max="100"></td>
        </tr>
      """

      $row.find("input")
        .val(initialValue)
        .on "change", () ->
          val = $(this).val()
          onChange(val)
          $(this).blur()

      @$("table").append $row

  class Sliders extends SlidersView
    constructor: () ->
      workspace = Workspace.getInstance()
      super()
      @render()
      workspace.addTopLeft @$el

  _.extend Sliders, Singleton
