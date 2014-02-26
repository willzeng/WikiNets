(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define([], function() {
    var VisualSearchBox;
    return VisualSearchBox = (function(_super) {

      __extends(VisualSearchBox, _super);

      function VisualSearchBox(options) {
        this.options = options;
        this.searchNodes = __bind(this.searchNodes, this);
        VisualSearchBox.__super__.constructor.call(this);
      }

      VisualSearchBox.prototype.init = function(instances) {
        var x,
          _this = this;
        this.graphModel = instances["GraphModel"];
        this.selection = instances["NodeSelection"];
        this.listenTo(instances["KeyListener"], "down:191", function(e) {
          _this.$("input").focus();
          return e.preventDefault();
        });
        this.render();
        $(this.el).attr('id', 'vsplug').appendTo($('#omniBox'));
        console.log(x = this.el);
        return this.keys = ['search'];
      };

      VisualSearchBox.prototype.render = function() {
        var $button, $container, $input,
          _this = this;
        $container = $("<div id=\"visual-search-container\" style='padding-top:2px'/>").appendTo(this.$el);
        $input = $("<div class=\"visual_search\" />").appendTo($container);
        $button = $("<input type=\"button\" value=\"Go\" style='float:left' />").appendTo($container);
        this.searchQuery = {};
        $button.click(function() {
          return _this.searchNodes(_this.searchQuery);
        });
        $.get("/get_all_keys", function(data) {
          _this.keys = data;
          $(document).ready(function() {
            var visualSearch;
            return visualSearch = VS.init({
              container: $('.visual_search'),
              query: '',
              callbacks: {
                search: function(query, searchCollection) {
                  _this.searchQuery = {};
                  searchCollection.each(function(term) {
                    return _this.searchQuery[term.attributes.category] = term.attributes.value;
                  });
                  return console.log(query, searchCollection, _this.searchQuery);
                },
                facetMatches: function(callback) {
                  console.log(visualSearch.searchBox.value(), visualSearch.searchQuery.facets());
                  if (visualSearch.searchBox.value().indexOf('nodes') > -1) {
                    return $.get("/get_all_node_keys", function(data) {
                      _this.keys = data;
                      return callback(data);
                    });
                  } else if (visualSearch.searchBox.value().indexOf('links') > -1) {
                    return $.get("/get_all_link_keys", function(data) {
                      _this.keys = data;
                      return callback(data);
                    });
                  } else {
                    _this.keys = ['search'];
                    return callback(_this.keys);
                  }
                },
                valueMatches: function(facet, searchTerm, callback) {
                  if (facet === 'search') {
                    return callback(['links', 'nodes']);
                  } else {
                    return $.post("/get_all_key_values", {
                      property: facet
                    }, function(data) {
                      return callback(data);
                    });
                  }
                }
              }
            });
          });
          return data;
        });
        return this;
      };

      VisualSearchBox.prototype.searchNodes = function(searchQuery) {
        var _this = this;
        return $.post("/search_nodes", searchQuery, function(nodes) {
          var node, _i, _len, _results;
          _results = [];
          for (_i = 0, _len = nodes.length; _i < _len; _i++) {
            node = nodes[_i];
            _results.push(_this.graphModel.putNode(node));
          }
          return _results;
        });
      };

      return VisualSearchBox;

    })(Backbone.View);
  });

}).call(this);
