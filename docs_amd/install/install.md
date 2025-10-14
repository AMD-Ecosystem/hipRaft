<head>
  <meta charset="UTF-8">
  <meta name="description" content="hipRAFT documentation and API reference library">
  <meta name="keywords" content="Machine-Learning, Information-Retrieval, Primitives, Nearest-Neighbors, GPU, RAPIDS, ROCm-DS">
</head>

# Installing hipRAFT

You can install `hipRAFT` via AMD PyPI as described below. This is recommended for users of the code. For developers interested in modifying or contributing to the Open Source `hipRAFT` component, refer to the [Build instructions](./build.md).

## Requirements

hipRAFT requires ROCm 7.0.2 or later running on a ROCm-supported operating system. Using Ubuntu 22.04 or later is recommended.
For more information, see [ROCm-DS system requirements](https://rocm.docs.amd.com/projects/rocm-ds/en/docs-25.10/install/requirements.html).

The steps in this guide require a Conda installation. A minimal free version of Conda is [Miniforge](https://conda-forge.org/download/).

## Install hipRAFT via AMD PyPI

Packaged versions of hipRAFT and its dependencies are distributed via
[AMD PyPI](https://pypi.amd.com/simple). This section discusses how to install
hipRAFT via this package index.

Create and activate a Conda environment with Python 3.12 as shown below:

```bash
conda create --name hipraft python=3.12
conda activate hipraft
```

hipRAFT can then be installed into this environment using pip and the AMD PyPI URL:

```bash
pip install pylibhipraft==0.1.0 --extra-index-url=https://pypi.amd.com/simple
```
