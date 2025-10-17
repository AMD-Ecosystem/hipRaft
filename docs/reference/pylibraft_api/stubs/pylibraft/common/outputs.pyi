from __future__ import annotations
import functools as functools
import pylibraft as pylibraft
import warnings as warnings
__all__: list[str] = ['auto_convert_output', 'conv', 'convert_to_cai_type', 'convert_to_cupy', 'convert_to_torch', 'functools', 'import_warn_', 'no_conversion', 'pylibraft', 'warnings']
def auto_convert_output(f):
    """
    Decorator to automatically convert an output device_ndarray
        (or list or tuple of device_ndarray) into the configured
        `__cuda_array_interface__` compliant type.

    """
def conv(ret):
    ...
def convert_to_cai_type(device_ndarray):
    ...
def convert_to_cupy(device_ndarray):
    ...
def convert_to_torch(device_ndarray):
    ...
def import_warn_(lib):
    ...
def no_conversion(device_ndarray):
    ...
