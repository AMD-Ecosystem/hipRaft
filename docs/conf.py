
# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

version_number = "0.1.0" # TODO: Parse this from a centralized location.
left_nav_title = f"hipRAFT {version_number} documentation"

# for PDF output on Read the Docs
project = "hipRAFT"
author = "Advanced Micro Devices, Inc."
copyright = "Copyright (c) 2025 Advanced Micro Devices, Inc. All rights reserved."
version = version_number
release = version_number
cpp_maximum_signature_line_length = 10
setting_all_article_info = True
all_article_info_os = ["linux"]
all_article_info_author = ""

external_projects_current_project = "hipRAFT"

html_context = {
    "docs_header_version": "25.10"
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
    "sphinx_copybutton",
    "autoapi.extension"
]

myst_heading_anchors = 4  # or deeper if needed
autosectionlabel_prefix_document = True

# Breathe configuration for Doxygen
breathe_projects = {"RAFT": "./doxygen/xml"}  # Ensure Doxygen XML is in ./xml
breathe_default_project = "raft"

autoapi_type = "python"
autoapi_dirs = ["./reference/pylibraft_api/stubs"]
autoapi_file_patterns = ["*.pyi"]
autoapi_add_toctree_entry = False

source_suffix = {
    ".rst": "restructuredtext",
}
