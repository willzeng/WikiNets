// Generated by CoffeeScript 1.6.3
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

define([], function() {
  var SimpleSearchBox;
  return SimpleSearchBox = (function(_super) {
    __extends(SimpleSearchBox, _super);

    function SimpleSearchBox(options) {
      this.options = options;
      this.searchNodesSimple = __bind(this.searchNodesSimple, this);
      SimpleSearchBox.__super__.constructor.call(this);
    }

    SimpleSearchBox.prototype.init = function(instances) {
      var _this = this;
      this.graphModel = instances["GraphModel"];
      this.selection = instances["NodeSelection"];
      this.listenTo(instances["KeyListener"], "down:191", function(e) {
        _this.$("#searchBox").focus();
        return e.preventDefault();
      });
      this.render();
      $(this.el).attr('id', 'ssplug').appendTo($('#omniBox'));
      this.searchableKeys = {};
      return $.get("/get_all_node_keys", function(keys) {
        return _this.searchableKeys = keys;
      });
    };

    SimpleSearchBox.prototype.render = function() {
      var $autofillWrapper, $button, $container, $searchBox, films,
        _this = this;
      $container = $("<div id='visual-search-container'>").appendTo(this.$el);
      $searchBox = $('<input type="text" id="searchBox">').css("width", "235px").css("height", "25px").css("box-shadow", "2px 2px 4px #888888").css("border", "1px solid blue").appendTo($container);
      $button = $("<input type=\"button\" value=\"Go\" style='float:right' />").appendTo($container);
      $autofillWrapper = $('<div class="autofillWrapperClass" style="border: 1px solid black; border-top: none;"></div>').appendTo($container);
      $autofillWrapper.hide();
      films = new Bloodhound({
        datumTokenizer: function(d) {
          return Bloodhound.tokenizers.whitespace(d.name);
        },
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        prefetch: '../node_index_search_prefetch'
      });
      films.initialize();
      $searchBox.typeahead(null, {
        displayKey: 'value',
        source: films.ttAdapter(),
        templates: {
          suggestion: Handlebars.compile('<p><strong>{{name}}</strong> – {{name}}</p>')
        }
      });
      $(document).on("click", function() {
        return $autofillWrapper.hide();
      });
      $searchBox.on("click", function(e) {
        $autofillWrapper.show();
        e.stopPropagation();
        if ($searchBox.val() > 0) {
          return $searchBox.show();
        }
      });
      return $button.click(function() {
        _this.searchNodesSimple($searchBox.val());
        return $searchBox.val("");
      });
    };

    SimpleSearchBox.prototype.searchNodesSimple = function(searchQuery) {
      var _this = this;
      return $.post("/node_index_search", {
        checkKeys: this.searchableKeys,
        query: searchQuery
      }, function(nodes) {
        var modelNode, node, theNode, _i, _j, _len, _len1, _ref, _results;
        if (nodes.length < 1) {
          alert("No Results Found");
        }
        _results = [];
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          node = nodes[_i];
          _this.graphModel.putNode(node);
          _ref = _this.graphModel.getNodes();
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            theNode = _ref[_j];
            if (theNode['_id'] === node['_id']) {
              modelNode = theNode;
            }
          }
          _results.push(_this.selection.selectNode(modelNode));
        }
        return _results;
      });
    };

    return SimpleSearchBox;

  })(Backbone.View);
});
