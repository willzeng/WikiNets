(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define([], function() {
    var ListView;
    return ListView = (function(_super) {

      __extends(ListView, _super);

      function ListView(options) {
        this.options = options;
        this.assign_properties = __bind(this.assign_properties, this);
        this.addField = __bind(this.addField, this);
        this.deleteNode = __bind(this.deleteNode, this);
        this.cancelEditing = __bind(this.cancelEditing, this);
        this.addNode = __bind(this.addNode, this);
        ListView.__super__.constructor.call(this);
      }

      ListView.prototype.init = function(instances) {
        this.dataController = instances['local/Neo4jDataController'];
        this.graphModel = instances['GraphModel'];
        this.graphModel.on("change", this.update.bind(this));
        $(this.el).appendTo($('#maingraph'));
        return $(this.el).hide();
      };

      ListView.prototype.update = function() {
        var $container, allNodes,
          _this = this;
        this.$el.empty();
        allNodes = this.graphModel.getNodes();
        $container = $("<div class=\"listview-profile-helper\"/>").appendTo(this.$el);
        return _.each(allNodes, function(node) {
          return _this.addNode(node, $container);
        });
      };

      ListView.prototype.addNode = function(node, parent) {
        var $nodeDiv, $nodeEdit, allLinks, blacklist, header, link, neighbors, nodeHash,
          _this = this;
        blacklist = ["index", "x", "y", "px", "py", "fixed", "selected", "weight"];
        $nodeDiv = $("<div class=\"node-profile\"/>").appendTo(parent);
        header = this.findHeader(node);
        $("<div class=\"node-profile-title\">" + header + "</div>").appendTo($nodeDiv);
        _.each(node, function(value, property) {
          var makeLinks;
          value += "";
          if (blacklist.indexOf(property) < 0) {
            if (value != null) {
              makeLinks = value.replace(/((https?|ftp|dict):[^'">\s]+)/gi, "<a href=\"$1\" target=\"_blank\" style=\"target-new: tab;\">$1</a>");
            } else {
              makeLinks = value;
            }
            if (property !== "color") {
              return $("<div class=\"node-profile-property\">" + property + ":  " + makeLinks + "</div>").appendTo($nodeDiv);
            }
          }
        });
        $nodeEdit = $("<input id=\"NodeEditButton" + node['_id'] + "\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this node\"><br>").appendTo($nodeDiv);
        $nodeEdit.click(function() {
          return _this.editNode(node, $nodeDiv, blacklist);
        });
        allLinks = this.graphModel.getLinks();
        nodeHash = this.graphModel.get("nodeHash");
        neighbors = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = allLinks.length; _i < _len; _i++) {
            link = allLinks[_i];
            if (nodeHash(link.source) === nodeHash(node)) {
              _results.push(link.target);
            }
          }
          return _results;
        })();
        _.each(neighbors, function(neighbor) {
          var $linkProfile, $nButton, link, _i, _len;
          $nButton = $("<span class=\"node-profile-neighbor\">" + (_this.findHeader(neighbor)) + "</span>").appendTo($nodeDiv);
          $nButton.click(function() {
            return _this.addNode(neighbor, $nodeDiv);
          });
          $linkProfile = $("<div class=\"node-profile\">");
          $linkProfile.appendTo($nButton);
          for (_i = 0, _len = allLinks.length; _i < _len; _i++) {
            link = allLinks[_i];
            if ((nodeHash(link.source) === nodeHash(node)) && (nodeHash(link.target) === nodeHash(neighbor))) {
              link = link;
            }
          }
          _.each(link, function(value, property) {
            return $("<div class=\"node-profile-property\">" + property + ":  " + value + "</div>").appendTo($linkProfile);
          });
          $linkProfile.hide();
          $nButton.mouseenter(function() {
            return $linkProfile.show();
          });
          return $nButton.mouseleave(function() {
            return $linkProfile.hide();
          });
        });
        neighbors = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = allLinks.length; _i < _len; _i++) {
            link = allLinks[_i];
            if (nodeHash(link.target) === nodeHash(node)) {
              _results.push(link.source);
            }
          }
          return _results;
        })();
        return _.each(neighbors, function(neighbor) {
          var $linkProfile, $nButton, link, _i, _len;
          $nButton = $("<span class=\"node-profile-neighbor\">" + (_this.findHeader(neighbor)) + "</span>").appendTo($nodeDiv);
          $nButton.click(function() {
            return _this.addNode(neighbor, $nodeDiv);
          });
          $linkProfile = $("<div class=\"node-profile\">");
          $linkProfile.appendTo($nButton);
          for (_i = 0, _len = allLinks.length; _i < _len; _i++) {
            link = allLinks[_i];
            if ((nodeHash(link.source) === nodeHash(node)) && (nodeHash(link.target) === nodeHash(neighbor))) {
              link = link;
            }
          }
          _.each(link, function(value, property) {
            return $("<div class=\"node-profile-property\">" + property + ":  " + value + "</div>").appendTo($linkProfile);
          });
          $linkProfile.hide();
          $nButton.mouseenter(function() {
            return $linkProfile.show();
          });
          return $nButton.mouseleave(function() {
            return $linkProfile.hide();
          });
        });
      };

      ListView.prototype.editNode = function(node, nodeDiv, blacklist) {
        var $nodeCancel, $nodeDelete, $nodeMoreFields, $nodeSave, colorEditingField, colors, header, hexColors, nodeInputNumber, origColor,
          _this = this;
        console.log("Editing node: " + node['_id']);
        nodeInputNumber = 0;
        origColor = "#A9A9A9";
        colors = ["darkgray", "aqua", "black", "blue", "darkblue", "fuchsia", "green", "darkgreen", "lime", "maroon", "navy", "olive", "orange", "purple", "red", "silver", "teal", "yellow"];
        hexColors = ["#A9A9A9", "#00FFFF", "#000000", "#0000FF", "#00008B", "#FF00FF", "#008000", "#006400", "#00FF00", "#800000", "#000080", "#808000", "#FFA500", "#800080", "#FF0000", "#C0C0C0", "#008080", "#FFFF00"];
        header = this.findHeader(node);
        nodeDiv.html("<div class=\"node-profile-title\">Editing " + header + " (id: " + node['_id'] + ")</div><form id=\"Node" + node['_id'] + "EditForm\"></form>");
        _.each(node, function(value, property) {
          var newEditingFields;
          if (blacklist.indexOf(property) < 0 && ["_id", "text"].indexOf(property) < 0 && property !== "color") {
            newEditingFields = "<div id=\"Node" + node['_id'] + "EditDiv" + nodeInputNumber + "\" class=\"Node" + node['_id'] + "EditDiv\">\n  <input style=\"width:80px\" id=\"Node" + node['_id'] + "EditProperty" + nodeInputNumber + "\" value=\"" + property + "\" class=\"propertyNode" + node['_id'] + "Edit\"/> \n  <input style=\"width:80px\" id=\"Node" + node['_id'] + "EditValue" + nodeInputNumber + "\" value=\"" + value + "\" class=\"valueNode" + node['_id'] + "Edit\"/> \n  <input type=\"button\" id=\"removeNode" + node['_id'] + "Edit" + nodeInputNumber + "\" value=\"x\" onclick=\"this.parentNode.parentNode.removeChild(this.parentNode);\">\n</div>";
            $(newEditingFields).appendTo("#Node" + node['_id'] + "EditForm");
            return nodeInputNumber = nodeInputNumber + 1;
          } else if (property === "color") {
            if (__indexOf.call(colors, value) >= 0) {
              return origColor = hexColors[colors.indexOf(value)];
            } else if (__indexOf.call(hexColors, origColor) >= 0) {
              return origColor = value;
            }
          }
        });
        colorEditingField = '\
            <form action="#" method="post">\
                <div class="controlset">Color<input id="color' + node['_id'] + '" name="color' + node['_id'] + '" type="text" value="' + origColor + '"/></div>\
            </form>\
          ';
        $(colorEditingField).appendTo(nodeDiv);
        $("#color" + node['_id']).colorPicker({
          showHexField: false
        });
        $nodeMoreFields = $("<input id=\"moreNode" + node['_id'] + "EditFields\" type=\"button\" value=\"+\">").appendTo(nodeDiv);
        $nodeMoreFields.click(function() {
          _this.addField(nodeInputNumber, "Node" + node['_id'] + "Edit");
          return nodeInputNumber = nodeInputNumber + 1;
        });
        $nodeSave = $("<input name=\"nodeSaveButton\" type=\"button\" value=\"Save\">").appendTo(nodeDiv);
        $nodeSave.click(function() {
          var newNode, newNodeObj;
          newNodeObj = _this.assign_properties("Node" + node['_id'] + "Edit", $("#color" + node['_id']).val());
          if (newNodeObj[0]) {
            newNode = newNodeObj[1];
            newNode['_id'] = node['_id'];
            return _this.dataController.nodeEdit(node, newNode, function(savedNode) {
              _this.graphModel.filterNodes(function(node) {
                return !(savedNode['_id'] === node['_id']);
              });
              _this.graphModel.putNode(savedNode);
              return _this.cancelEditing(savedNode, nodeDiv, blacklist);
            });
          }
        });
        $nodeDelete = $("<input name=\"NodeDeleteButton\" type=\"button\" value=\"Delete\">").appendTo(nodeDiv);
        $nodeDelete.click(function() {
          if (confirm("Are you sure you want to delete this node?")) {
            return _this.deleteNode(node, function() {});
          }
        });
        $nodeCancel = $("<input name=\"NodeCancelButton\" type=\"button\" value=\"Cancel\">").appendTo(nodeDiv);
        return $nodeCancel.click(function() {
          return _this.cancelEditing(node, nodeDiv, blacklist);
        });
      };

      ListView.prototype.cancelEditing = function(node, nodeDiv, blacklist) {
        var $nodeEdit,
          _this = this;
        nodeDiv.html("<div class=\"node-profile-title\">" + (this.findHeader(node)) + "</div>");
        _.each(node, function(value, property) {
          if (blacklist.indexOf(property) < 0) {
            return $("<div class=\"node-profile-property\">" + property + ":  " + value + "</div>").appendTo(nodeDiv);
          }
        });
        $nodeEdit = $("<input id=\"NodeEditButton" + node['_id'] + "\" class=\"NodeEditButton\" type=\"button\" value=\"Edit this node\">").appendTo(nodeDiv);
        return $nodeEdit.click(function() {
          return _this.editNode(node, nodeDiv, blacklist);
        });
      };

      ListView.prototype.deleteNode = function(delNode, callback) {
        var _this = this;
        return this.dataController.nodeDelete(delNode, function(response) {
          if (response === "error") {
            if (confirm("Could not delete node. There might be links remaining on this node. Do you want to delete the node (and all links to it) anyway?")) {
              return _this.dataController.nodeDeleteFull(delNode, function(responseFull) {
                console.log("Node Deleted");
                _this.graphModel.filterNodes(function(node) {
                  return !(delNode['_id'] === node['_id']);
                });
                return callback();
              });
            }
          } else {
            console.log("Node Deleted");
            _this.graphModel.filterNodes(function(node) {
              return !(delNode['_id'] === node['_id']);
            });
            return callback();
          }
        });
      };

      ListView.prototype.addField = function(inputIndex, name, defaultKey, defaultValue) {
        var $row;
        if (!(defaultKey != null)) defaultKey = "propertyEx";
        if (!(defaultValue != null)) defaultValue = "valueEx";
        $row = $("<div id=\"" + name + "Div" + inputIndex + "\" class=\"" + name + "Div\">\n<input style=\"width:80px\" name=\"property" + name + inputIndex + "\" placeholder=\"" + defaultKey + "\" class=\"property" + name + "\">\n<input style=\"width:80px\" name=\"value" + name + inputIndex + "\" placeholder=\"" + defaultValue + "\" class=\"value" + name + "\">\n<input type=\"button\" id=\"remove" + name + inputIndex + "\" value=\"x\" onclick=\"this.parentNode.parentNode.removeChild(this.parentNode);\">\n</div>");
        return $("#" + name + "Form").append($row);
      };

      ListView.prototype.assign_properties = function(form_name, colorValue, is_illegal) {
        var propertyObject, submitOK;
        if (is_illegal == null) is_illegal = this.dataController.is_illegal;
        submitOK = true;
        propertyObject = {};
        propertyObject["color"] = colorValue;
        $("." + form_name + "Div").each(function(i, obj) {
          var property, value;
          property = $(this).children(".property" + form_name).val();
          value = $(this).children(".value" + form_name).val();
          if (is_illegal(property, "Property")) {
            return submitOK = false;
          } else if (property in propertyObject) {
            alert("Property '" + property + "' already assigned.\nFirst value: " + propertyObject[property] + "\nSecond value: " + value);
            return submitOK = false;
          } else {
            return propertyObject[property] = value.replace(/'/g, "\\'");
          }
        });
        return [submitOK, propertyObject];
      };

      ListView.prototype.findHeader = function(node) {
        if (node.name != null) {
          return node.name;
        } else if (node.title != null) {
          return node.title;
        } else {
          return '';
        }
      };

      return ListView;

    })(Backbone.View);
  });

}).call(this);
