<!---
    MIT License

    Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
-->

# Generating the stubs

In order to generate the Python API documentation from an environment where
`raft-dask` is unavailable, the stubs must be generated. This can be done by
running the following commands:

From an environment with `raft-dask` installed (and `LD_LIBRARY_PATH` set to
include the shared libraries, e.g.
`/home/kjoseph/.local/share/mamba/envs/hipvs/lib`), run:

```bash
pip install pybind11-stubgen
cd <HIPRAFT_ROOT>/docs_amd/reference/hipraft_dask_api
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask.common
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask.common.comms
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask.common.comms_utils
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask.common.nccl
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask.common.ucx
pybind11-stubgen --ignore-all-errors --output-dir stubs raft_dask.common.utils
```

The generated stubs are checked into the repository, so this step should only
be necessary if the API has changed. These stubs are then used by the
`autoapi.extension` to generate the API documentation.
