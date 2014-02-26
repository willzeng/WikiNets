(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define([], function() {
    var LinkHover;
    return LinkHover = (function(_super) {

      __extends(LinkHover, _super);

      function LinkHover(options) {
        this.options = options;
        this.expandSelection = __bind(this.expandSelection, this);
        LinkHover.__super__.constructor.call(this);
      }

      LinkHover.prototype.init = function(instances) {
        var _this = this;
        _.extend(this, Backbone.Events);
        this.graphView = instances['GraphView'];
        this.linkFilter = this.graphView.getLinkFilter();
        this.graphModel = instances['GraphModel'];
        this.dataProvider = instances["local/WikiNetsDataProvider"];
        this.topBarCreate = instances['local/TopBarCreate'];
        this.graphView.on("enter:node:mouseover", function(d) {
          return $('#expand-button' + _this.graphModel.get("nodeHash")(d)).show();
        });
        this.graphView.on("enter:node:mouseout", function(d) {
          return $('#expand-button' + _this.graphModel.get("nodeHash")(d)).hide();
        });
        this.graphView.on("enter:node:rect:click", function(d) {
          return _this.expandSelection(d);
        });
        this.graphView.on("enter:link:mouseover", function(d) {
          if (!_this.topBarCreate.buildingLink) {
            return $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px">' + 'Click to select: <b>' + d.source.name + " - " + d.name + " - " + d.target.name + '</b></span>');
          }
        });
        return this.graphView.on("enter:link:mouseout", function(d) {
          if (!_this.topBarCreate.buildingLink) {
            return $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:black; font-size:20px"></span>');
          }
        });
      };

      LinkHover.prototype.expandSelection = function(d) {
        var _this = this;
        return this.dataProvider.getLinkedNodes([d], function(nodes) {
          return _.each(nodes, function(node) {
            if (_this.dataProvider.nodeFilter(node)) {
              return _this.graphModel.putNode(node);
            }
          });
        });
      };

      return LinkHover;

    })(Backbone.View);
  });

}).call(this);
