define(['jquery', 'jquery.typeahead', 'underscore', 'backbone', 'd3'], 
function($, ignore, _, Backbone, d3) {

  describe('global library: ', function() {

    it('jquery loads', function() {
      expect($).not.toBeUndefined();
    });

    it('typeahead loads', function() {
      expect(typeof $.fn.typeahead).toBe("function");
    });

    it('underscore loads', function() {
      expect(_).not.toBeUndefined();
    });

    it('backbone loads', function() {
      expect(Backbone).not.toBeUndefined();
    });

    it('d3 loads', function() {
      expect(d3).not.toBeUndefined();
    });

  });

});
