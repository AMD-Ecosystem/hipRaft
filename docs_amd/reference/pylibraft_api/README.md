<!---
    MIT License

    Modifications Copyright (C) 2025 Advanced Micro Devices, Inc. All rights reserved.

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

In order to generate the python API documentation from an environment where amd-pylibraft is unavailable, the stubs must be generated. This can be done by running the following commands:

```bash

From an environment with `amd-pylibraft` installed run:

```bash
pip install pybind11-stubgen
cd <HIPRAFT_ROOT>/docs/reference/pylibraft_api
pybind11-stubgen --ignore-all-errors pylibraft.common
pybind11-stubgen --ignore-all-errors pylibraft.common.interruptible
pybind11-stubgen --ignore-all-errors pylibraft.common.cai_wrapper
pybind11-stubgen --ignore-all-errors pylibraft.random.rmat_rectangular_generator
pybind11-stubgen --ignore-all-errors pylibraft.sparse.linalg.eigsh
```
The generated stubs are checked into the repository, so this step should only be necessary if the API has changed. These stubs are then used by the autoapi.extension to generate the API documentation.
