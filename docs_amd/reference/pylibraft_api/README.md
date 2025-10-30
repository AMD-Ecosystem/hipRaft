# Generating the stubs

In order to generate the python API documentation from an environment where amd-pylibraft is unavailable, the stubs must be generated. This can be done by running the following commands:

```bash

From an environment with `amd-pylibraft` installed run:

```bash
pip install pybind11-stubgen
cd <HIPRAFT_ROOT>/docs_amd/reference/pylibraft_api
pybind11-stubgen --ignore-all-errors pylibraft.common
pybind11-stubgen --ignore-all-errors pylibraft.common.interruptible
pybind11-stubgen --ignore-all-errors pylibraft.common.cai_wrapper
pybind11-stubgen --ignore-all-errors pylibraft.random.rmat_rectangular_generator
pybind11-stubgen --ignore-all-errors pylibraft.sparse.linalg.eigsh
```
The generated stubs are checked into the repository, so this step should only be necessary if the API has changed. These stubs are then used by the autoapi.extension to generate the API documentation.
