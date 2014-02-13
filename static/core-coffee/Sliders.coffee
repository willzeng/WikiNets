###

provides an interface to add sliders to the ui

`addSlider(label, initialValue, onChange)` does the following
  - shows the text `label` next to the slider
  - starts it at `initialValue`
  - calls `onChange` when the value changes
    with the new value as the argument

sliders have range [0, 100]

###
define [], () ->

  class SlidersView extends Backbone.View

    constructor: (@options) ->
      super()

    init: (instances) ->
      @render()
      #$(@el).hide()

      $(@el).attr("id", "slidersPopOut").attr("class", "toolboxpopout")
      $(@el).appendTo $("#maingraph")

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
