Joe Henke's 6.UAP Code
===
[An Interface to Understand Inference of Semantic Networks](./PROPOSAL.md)

# Setup

Install dependencies using [virtualenv](https://pypi.python.org/pypi/virtualenv).

```bash
virtualenv env
source env/bin/activate
pip install numpy
pip install divisi2 csc-pysparse
pip install simplejson
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

# License

See [LICENSE](./LICENSE)
