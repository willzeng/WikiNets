tests = []
for file of window.__karma__.files
  tests.push file  if /Spec\.js$/.test(file)
requirejs.config
  
  # Karma serves files from '/base'
  baseUrl: "/base"
  paths:
    jquery: "lib/jquery"
    "jquery.typeahead": "lib/jquery.typeahead"
    underscore: "lib/underscore"
    backbone: "lib/backbone"
    d3: "lib/d3"

  shim:
    "jquery.typeahead": ["jquery"]
    d3:
      exports: "d3"

    underscore:
      exports: "_"

    backbone:
      deps: ["underscore"]
      exports: "Backbone"

  
  # ask Require.js to load these files (all our tests)
  deps: tests
  
  # start test run, once Require.js is done
  callback: window.__karma__.start

