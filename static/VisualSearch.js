// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define([], function() {
    var VisualSearchBox;
    return VisualSearchBox = (function(_super) {
      __extends(VisualSearchBox, _super);

      function VisualSearchBox(options) {
        this.options = options;
        VisualSearchBox.__super__.constructor.call(this);
      }

      VisualSearchBox.prototype.init = function(instances) {
        var _this = this;
        this.graphModel = instances["GraphModel"];
        this.listenTo(instances["KeyListener"], "down:191", function(e) {
          _this.$("input").focus();
          return e.preventDefault();
        });
        this.render();
        return instances["Layout"].addPlugin(this.el, this.options.pluginOrder, 'Visual Search', true);
      };

      VisualSearchBox.prototype.render = function() {
        var $container, $input,
          _this = this;
        $container = $("<div id=\"visual-search-container\"/>").appendTo(this.$el);
        $input = $("<div class=\"visual_search\" />").appendTo($container);
        $.get("/get_all_node_keys", function(data) {
          _this.keys = data[0];
          _this.values = data[1];
          console.log(_this.keys);
          $(document).ready(function() {
            var visualSearch;
            return visualSearch = VS.init({
              container: $('.visual_search'),
              query: '',
              callbacks: {
                search: function(query, searchCollection) {
                  return {};
                },
                facetMatches: function(callback) {
                  return callback(_this.keys);
                },
                valueMatches: function(facet, searchTerm, callback) {
                  return callback(_this.values[facet]);
                }
              }
            });
          });
          return data;
        });
        return this;
      };

      VisualSearchBox.prototype.addNode = function(e, datum) {
        var h, newNode, newNodeHash;
        newNode = {
          text: datum.value,
          '_id': -1
        };
        h = this.graphModel.get("nodeHash");
        newNodeHash = h(newNode);
        if (!_.some(this.graphModel.get("nodes"), function(node) {
          return h(node) === newNodeHash;
        })) {
          this.graphModel.putNode(newNode);
        }
        return $(e.target).blur();
      };

      return VisualSearchBox;

    })(Backbone.View);
  });

}).call(this);