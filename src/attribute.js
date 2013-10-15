define(['backbone'], function(Backbone) {

  var Attribute = Backbone.Model.extend({

  });

  var NominalAttribute = Attribute.extend({

  });

  var OrderedAttribute = Attribute.extend({

  });

  var QuantitativeAttribute = Attribute.extend({

  });

  return {
    'Nominal': NominalAttribute,
    'Ordered': OrderedAttribute,
    'Quantitative': QuantitativeAttribute,
  }
});