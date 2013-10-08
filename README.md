Celestrium
==========

> [Require.js](http://requirejs.org/) modules to create a completey customizable graph explorer.

<img src="https://travis-ci.org/jdhenke/celestrium.png">

## Introduction

### Recommended Reading
[require.js](http://requirejs.org/) and [git submodules](http://git-scm.com/book/en/Git-Tools-Submodules).

### Overview

Here's the general setup.

  - This repo is just a collection of require.js modules.
  - It should be embedded as a submodule in the scripts folder of a website.
  - The require.js main script can then require the modules defined in celestrium.

### Example Repo Structure
Here's an example repo layout for a static site being served out of `www`

      repo-root/
        run-server.sh <== whatever you want
        www/
          index.html <== html of page being served; should only pull in require.js, referencing main.js
          scripts/
            require.js <== standard library
            ...global libraries... <== jquery, jquery.typeahead, underscore, Backbone, d3
            main.js  <== require.js main
            celestrium/  <== this repo added as a git submodule
              ...celestrium modules...
              README.md <== this file (so meta)
### Example Implementation

Checkout my [6.UAP repo](https://github.com/jdhenke/uap).

## [Contributing](./CONTRIBUTING.md) && [License](./LICENSE)
