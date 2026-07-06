<!---
    MIT License

    Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.

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

The Python API reference is built with `sphinx-autoapi` from `.pyi` type stubs
so that the documentation can be generated in environments where `raft-dask` is
not installed. The generated stubs (under `stubs/`) are checked into the
repository and are auto-generated, so they only need to be regenerated when the
`raft_dask` public API changes.

To regenerate them, run the script from a Python environment with `raft_dask`
(and its Dask/UCX dependencies) and `pybind11-stubgen` installed:

```bash
pip install pybind11-stubgen
./generate_stubs.sh
```

The script runs `pybind11-stubgen` over the curated list of public `raft_dask`
submodules (the compiled Cython extensions are not reliably discovered by
`pkgutil.walk_packages`, so they are enumerated explicitly in the script). When
a new public module is added, add it both to the `MODULES` list in
`generate_stubs.sh` and to the relevant `autoapi` directive in the `*.rst`
pages. The stubs are then consumed by the `autoapi` extension to generate the
API documentation.
