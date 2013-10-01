Celestrium

> Require.js modules to create data driven interfaces.

## Using

Add this repo as a [git submodule](http://git-scm.com/book/en/Git-Tools-Submodules) to your Require.js application.

```bash
git submodule add git@github.com:jdhenke/celestrium.git www/scripts/celestrium
```

Ensure these dependencies are in `scripts`

  - jquery
  - jquery.typeahead
  - underscore
  - d3

Use these modules in your `main.js`.

```javascript
requirejs(["celestrium/TODO"], function(TODO) {
  // do awesome stuff with TODO
});
```

## Contributing

Branch from `master` to a topic branch, then make a pull request to `master`.

## Copying

See [LICENSE](./LICENSE)
