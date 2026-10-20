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

import os

_version_file = os.path.join(os.path.dirname(__file__), "..", "VERSION")
with open(_version_file) as _f:
    version_number = ".".join(
        str(int(p)) for p in _f.read().strip().split(".")
    )
left_nav_title = f"hipRAFT {version_number} documentation"

# for PDF output on Read the Docs
project = "hipRAFT"
author = "Advanced Micro Devices, Inc."
copyright = (
    "Copyright (c) 2026 Advanced Micro Devices, Inc. All rights reserved."
)
version = version_number
release = version_number
cpp_maximum_signature_line_length = 10
setting_all_article_info = True
all_article_info_os = ["linux"]
all_article_info_author = ""

# Must match the (lower-case) key in rocm-docs-core's projects.yaml, not the
# display name in `project` above.
external_projects_current_project = "hipraft"

# rocm-docs-core defaults this to "all", which makes every build fetch an
# `objects.inv` from all ~94 ROCm project doc sites. Nothing here uses an
# `:external:` cross-reference, so the mappings are pure overhead -- and the
# build hard-fails whenever one of those sites serves an HTML error page with a
# 200 status (intersphinx warns on HTTP errors but raises on unparseable
# content). Keep this list empty unless a real cross-project reference is added.
external_projects: list[str] = []

html_context = {"docs_header_version": "26.10"}
html_theme = "rocm_docs_theme"
html_theme_options = {
    "flavor": "rocm-ds",
    "repository_url": "https://github.com/AMD-Ecosystem/hipRaft/",
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
    "autoapi.extension",
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
# The curated `reference/*_api/*.rst` pages pull in each symbol explicitly via
# `autoapiclass`/`autoapifunction`, so autoapi's own per-module pages are not
# needed. Leaving them enabled publishes ~24 orphan pages that are excluded from
# the nav but still land in the search index, duplicating the curated pages and
# raising a `duplicate object description` warning for every symbol.
autoapi_generate_api_docs = False

# Maintainer notes that live alongside the docs sources (how to regenerate the
# pyi stubs); they are not user-facing documentation and must not be published.
exclude_patterns = [
    "reference/pylibraft_api/README.md",
    "reference/hipraft_dask_api/README.md",
]

source_suffix = {
    ".rst": "restructuredtext",
}
external_projects_remote_repository = ""
