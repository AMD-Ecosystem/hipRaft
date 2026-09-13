.. meta::
   :description: hipRAFT documentation and API reference library
   :keywords: Machine-Learning, Information-Retrieval, Primitives, Nearest-Neighbors, GPU, RAPIDS, AMD-DS

..
    MIT License

    Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.

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

******************
Installing hipRAFT
******************

You can install hipRAFT via AMD PyPI as described below. This is recommended for users of the code. For developers interested in modifying or contributing to the Open Source hipRAFT component, see the :doc:`Build instructions <./build>`.

See :ref:`sys-req` for information regarding supported operating systems, ROCm versions,
and AMD GPUs before installing hipRAFT.

Install hipRAFT via AMD PyPI
=============================

Packaged versions of hipRAFT and its dependencies are distributed via
`AMD PyPI <https://pypi.amd.com/rocm-10.0.0/simple/>`_. This section discusses how to install
hipRAFT via this package index.

Create and activate a Conda environment with a compatible Python version, such as 3.11 or 3.12 as shown below. For more information on compatible Python versions, see :ref:`sys-req`.

.. code-block:: bash

   conda create --name hipraft python=3.12 # Specify your Python version
   conda activate hipraft

hipRAFT can then be installed into this environment using pip and the AMD PyPI URL:

.. code-block:: bash

   pip install amd-pylibraft==2.0.0 --extra-index-url=https://pypi.amd.com/rocm-10.0.0/simple/

hipRAFT is published as two wheels:

.. list-table::
   :header-rows: 1
   :widths: 30 70

   * - Package
     - Contents
   * - ``amd-libraft``
     - The hipRAFT C++ headers and the ``libraft`` shared library.
   * - ``amd-pylibraft``
     - The Python bindings. Installing this package pulls in a matching ``amd-libraft``.

Installing ``amd-pylibraft`` is sufficient for Python workloads. To install only the C++
artifacts, for example when building a downstream C++ project against hipRAFT, install
``amd-libraft`` on its own:

.. code-block:: bash

   pip install amd-libraft==2.0.0 --extra-index-url=https://pypi.amd.com/rocm-10.0.0/simple/
