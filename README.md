Celestrium
===

A tool to understand your [graph](http://en.wikipedia.org/wiki/Graph_(mathematics)ical data.

## Local Setup

Install dependencies using [virtualenv](https://pypi.python.org/pypi/virtualenv).

```bash
# setup virtual environment
virtualenv env
source env/bin/activate

# install normal dependencies
pip install -r requirements.txt

# install these *special* dependencies
# this is a result of them depending on numpy in their setup.py's
pip install divisi2 csc-pysparse
```

Test to see if it's working by running this in python.

```python
import divisi2
A = divisi2.network.conceptnet_matrix('en')
concept_axes, axis_weights, feature_axes = A.svd(k=100)
predictions = divisi2.reconstruct(concept_axes, axis_weights, feature_axes)
predictions.entry_named('pig', ('right', 'HasA', 'leg'))
predictions.entry_named('pig', ('right', 'CapableOf', 'fly'))
```

I get a ~0.1261 and ~-0.1784 for the last two calls respectively, but I can't say if this is consisent across installs.

## Deploying to [Heroku](https://www.heroku.com/)

This will use the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-command).

```bash
git checkout -b prod # do all these changes on a different branch
heroku create
git push heroku prod:master
```

Now, edit `requirements.txt` to uncomment the bottom list of packages.

> This is necessary because those packages require numpy to be *fully* installed before even starting to install these packages. Hence the two stages.

Commit the changes and push to heroku so it recognizes and installs the remaining packages.

```bash
git add requirements.txt
git commit -m 'adding second set of requirements'
git push heroku prod:master
```

Check the logs to see when things are finally up, then check it out.

```bash
heroku logs --tail
heroku open
```

## License

See [LICENSE](./LICENSE)
