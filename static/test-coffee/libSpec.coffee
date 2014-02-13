define [
  "jquery"
  "jquery.typeahead"
  "underscore"
  "backbone"
  "d3"
], ($, ignore, _, Backbone, d3) ->
  describe "global library: ", ->
    it "jquery loads", ->
      expect($).not.toBeUndefined()

    it "typeahead loads", ->
      expect(typeof $.fn.typeahead).toBe "function"

    it "underscore loads", ->
      expect(_).not.toBeUndefined()

    it "backbone loads", ->
      expect(Backbone).not.toBeUndefined()

    it "d3 loads", ->
      expect(d3).not.toBeUndefined()



