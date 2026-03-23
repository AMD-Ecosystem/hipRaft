# MIT License
#
# Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

version_number = "1.0.0" # TODO: Parse this from a centralized location.
left_nav_title = f"hipRAFT {version_number} documentation"

# for PDF output on Read the Docs
project = "hipRAFT"
author = "Advanced Micro Devices, Inc."
copyright = "Copyright (c) 2026 Advanced Micro Devices, Inc. All rights reserved."
version = version_number
release = version_number
cpp_maximum_signature_line_length = 10
setting_all_article_info = True
all_article_info_os = ["linux"]
all_article_info_author = ""

external_projects_current_project = "hipRAFT"

html_context = {
    "docs_header_version": "26.03"
}
html_theme = "rocm_docs_theme"
html_theme_options = {
    "flavor": "rocm-ds",
    "repository_url": "https://github.com/AMD-AIOSS/hipRaft/"
}

external_toc_path = "./sphinx/_toc.yml"
doxygen_root = "doxygen"
doxysphinx_enabled = True
doxygen_project = {
    "name": "doxygen",
    "path": "doxygen/xml",
}

extensions = [
    "rocm_docs",
    "rocm_docs.doxygen",
    "breathe",
    "sphinx.ext.intersphinx",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosectionlabel",
    "sphinx.ext.autosummary",
    "sphinx.ext.doctest",
    "sphinx.ext.napoleon",
    "sphinx_copybutton",
    "autoapi.extension"
]

myst_heading_anchors = 4  # or deeper if needed
autosectionlabel_prefix_document = True

# Breathe configuration for Doxygen
breathe_projects = {"RAFT": "./doxygen/xml"}  # Ensure Doxygen XML is in ./xml
breathe_default_project = "raft"

autoapi_type = "python"
autoapi_dirs = [
    "./reference/pylibraft_api/stubs",
    "./reference/hipraft_dask_api/stubs",
]
autoapi_file_patterns = ["*.pyi"]
autoapi_add_toctree_entry = False

source_suffix = {
    ".rst": "restructuredtext",
}
