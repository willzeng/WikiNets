How to Contribute
=================

[Fork](https://github.com/jdhenke/celestrium/fork) the repo and make a pull request to Celestrium's `master` branch.

### Checklist for issuing a pull request

  * merge Celestrium's current `master` into your branch to make it as current as possible
  * ensure your repo passes CI by running `npm install && npm test`
  * new code should have:
    * at least one test for it
    * documentation on how to use it
    * a code snippet showing an example use case
  * bug fixes should have:
    * a description of the current behavior and the desired behavior
    * a new test catching this bug
    * an implemented solution
  * your changes should be data-set agnostic
  * styling should be avoided if possible, but if not, make it simple and easy to override
