// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define([], function() {
    var TopBarCreate;
    return TopBarCreate = (function(_super) {
      __extends(TopBarCreate, _super);

      function TopBarCreate(options) {
        this.options = options;
        TopBarCreate.__super__.constructor.call(this);
      }

      TopBarCreate.prototype.init = function(instances) {
        _.extend(this, Backbone.Events);
        this.keyListener = instances['KeyListener'];
        this.graphView = instances['GraphView'];
        this.graphModel = instances['GraphModel'];
        this.dataController = instances['local/Neo4jDataController'];
        this.buildingLink = false;
        this.sourceSet = false;
        this.tempLink = {};
        this.render();
        $(this.el).appendTo($('#buildbar'));
        this.selection = instances["NodeSelection"];
        return this.selection.on("change", this.update.bind(this));
      };

      TopBarCreate.prototype.render = function() {
        var $container, $createLinkButton, $createnodeNodeButton, $linkHolder, $linkInputDesc, $linkInputName, $linkInputUrl, $linkSide, $linkingInstructions, $nodeHolder, $nodeInputDesc, $nodeInputName, $nodeInputUrl, $nodeSide,
          _this = this;
        $container = $('<div id="topbarcreate">').appendTo(this.$el);
        $nodeSide = $('<div id="nodeside">').appendTo($container);
        $nodeHolder = $('<textarea placeholder="Add Node" id="nodeHolder" name="textin" rows="1" cols="35"></textarea>').appendTo($nodeSide);
        this.$nodeWrapper = $('<div class="source-container">').appendTo($nodeSide);
        $nodeInputName = $('<textarea placeholder=\"Node Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo(this.$nodeWrapper);
        $nodeInputUrl = $('<textarea placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo(this.$nodeWrapper);
        $nodeInputDesc = $('<textarea placeholder="Description #key1 value1 #key2 value2" rows="5" cols="35"></textarea><br>').appendTo(this.$nodeWrapper);
        $createnodeNodeButton = $('<input id="queryform" type="button" value="Create Node">').appendTo(this.$nodeWrapper);
        $createnodeNodeButton.click(function() {
          _this.buildNode(_this.parseSyntax($nodeInputName.val() + " : " + $nodeInputDesc.val() + " #url " + $nodeInputUrl.val()));
          $nodeInputName.val('');
          $nodeInputUrl.val('');
          $nodeInputDesc.val('');
          return $nodeInputName.focus();
        });
        $linkSide = $('<div id="linkside">').appendTo($container);
        $linkHolder = $('<textarea placeholder="Add Link" id="nodeHolder" name="textin" rows="1" cols="35"></textarea><br>').appendTo($linkSide);
        this.$linkWrapper = $('<div id="source-container">').appendTo($linkSide);
        $linkInputName = $('<textarea placeholder=\"Link Name [optional]\" rows="1" cols="35"></textarea><br>').appendTo(this.$linkWrapper);
        $linkInputUrl = $('<textarea placeholder="Url [optional]" rows="1" cols="35"></textarea><br>').appendTo(this.$linkWrapper);
        $linkInputDesc = $('<textarea placeholder="Description\n #key1 value1 #key2 value2" rows="5" cols="35"></textarea><br>').appendTo(this.$linkWrapper);
        $createLinkButton = $('<input id="queryform" type="submit" value="Create Link"><br>').appendTo(this.$linkWrapper);
        $linkingInstructions = $('<span id="toplink-instructions">').appendTo($container);
        $createLinkButton.click(function() {
          var tlink;
          _this.buildLink(tlink = _this.parseSyntax($linkInputName.val() + " : " + $linkInputDesc.val() + " #url " + $linkInputUrl.val()));
          $linkInputName.val('');
          $linkInputUrl.val('');
          $linkInputDesc.val('');
          _this.$linkWrapper.hide();
          return $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:yellow; font-size:20px">Click two Nodes to link them.</span>');
        });
        this.$nodeWrapper.hide();
        this.$linkWrapper.hide();
        $nodeHolder.focus(function() {
          _this.$nodeWrapper.show();
          $nodeInputName.focus();
          return $nodeHolder.hide();
        });
        $linkHolder.focus(function() {
          _this.$linkWrapper.show();
          $linkInputName.focus();
          return $linkHolder.hide();
        });
        this.graphView.on("view:click", function() {
          if (_this.$nodeWrapper.is(':visible')) {
            _this.$nodeWrapper.hide();
            $nodeHolder.show();
          }
          if (_this.$linkWrapper.is(':visible')) {
            _this.$linkWrapper.hide();
            return $linkHolder.show();
          }
        });
        return this.graphView.on("enter:node:click", function(node) {
          var link;
          if (_this.buildingLink) {
            if (_this.sourceSet) {
              _this.tempLink.target = node;
              link = _this.tempLink;
              _this.dataController.linkAdd(link, function(linkres) {
                var allNodes, n, newLink, _i, _j, _len, _len1;
                newLink = linkres;
                allNodes = _this.graphModel.getNodes();
                for (_i = 0, _len = allNodes.length; _i < _len; _i++) {
                  n = allNodes[_i];
                  if (n['_id'] === link.source['_id']) {
                    newLink.source = n;
                  }
                }
                for (_j = 0, _len1 = allNodes.length; _j < _len1; _j++) {
                  n = allNodes[_j];
                  if (n['_id'] === link.target['_id']) {
                    newLink.target = n;
                  }
                }
                return _this.graphModel.putLink(newLink);
              });
              _this.sourceSet = _this.buildingLink = false;
              $('#toplink-instructions').replaceWith('<span id="toplink-instructions"></span>');
              return $linkHolder.show();
            } else {
              _this.tempLink.source = node;
              _this.sourceSet = true;
              return $('#toplink-instructions').replaceWith('<span id="toplink-instructions" style="color:yellow; font-size:20px">Click two Nodes to link them.</span>');
            }
          }
        });
      };

      TopBarCreate.prototype.update = function(node) {
        return this.selection.getSelectedNodes();
      };

      TopBarCreate.prototype.buildNode = function(node) {
        var _this = this;
        return this.dataController.nodeAdd(node, function(datum) {
          return _this.graphModel.putNode(datum);
        });
      };

      TopBarCreate.prototype.buildLink = function(linkProperties) {
        this.tempLink.properties = linkProperties;
        console.log("tempLink set to", this.tempLink);
        return this.buildingLink = true;
      };

      TopBarCreate.prototype.parseSyntax = function(input) {
        var createDate, dict, match, pattern, strsplit, text;
        console.log("input", input);
        strsplit = input.split('#');
        strsplit[0] = strsplit[0].replace(/:/, " #description ");
        /* The : is shorthand for #description*/

        text = strsplit.join('#');
        pattern = new RegExp(/#([a-zA-Z0-9]+) ([^#]+)/g);
        dict = {};
        match = {};
        while (match = pattern.exec(text)) {
          dict[match[1].trim()] = match[2].trim();
        }
        /*The first entry becomes the name*/

        dict["name"] = text.split('#')[0].trim();
        console.log("This is the title", text.split('#')[0].trim());
        createDate = new Date();
        dict["Creation_Date"] = createDate;
        return dict;
      };

      return TopBarCreate;

    })(Backbone.View);
  });

}).call(this);
