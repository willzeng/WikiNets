define(["jquery", "underscore", "backbone"], function($, _, Backbone) {

  return Backbone.View.extend({

    initialize: function() {
      this.selection = this.options.selection;
      this.selection.on("select", this.update.bind(this));
    },

    render: function() {    
      return this;
    },

    update: function() {
      this.$el.empty();
      var $container = $('<div class="node-profile-section"/>').appendTo(this.$el);
      var selectedNodes = this.selection.getSelectedNodes();

      for (var i in selectedNodes)
      {
        var node = selectedNodes[i];
        var $nodeDiv = $('<div class="node-profile"/>').appendTo($container);
        $('<span class="node-profile-title">' + node['text'] + '</span><br>').appendTo($nodeDiv);
        for (var prop in node)
        {
          var blacklist = ["text",'index','x','y','px','py','fixed','selected'];
          if (blacklist.indexOf(prop) == -1) {
            $('<span class="node-profile-properties">' + prop + ':  ' + node[prop] + '</span><br>').appendTo($nodeDiv);
          }
        }
      }
    
    },

    toggle: function() {
      if (this.$el.css("display") == "none")
      {
        this.$el.css("display","block");
      }
      else {
        this.$el.css("display","none");
      }      
    },

  });
});