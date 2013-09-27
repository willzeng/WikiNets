Celestrium
===

A tool to understand your graph based data.

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

Install the [Heroku Toolbelt](https://toolbelt.heroku.com/).

## Running Locally

```bash
foreman start
```

## Deploying to [Heroku](https://www.heroku.com/)

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
