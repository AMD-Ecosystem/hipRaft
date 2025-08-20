from __future__ import annotations
import pylibraft.common.ai_wrapper
from pylibraft.common.ai_wrapper import ai_wrapper
from types import SimpleNamespace
__all__: list[str] = ['SimpleNamespace', 'ai_wrapper', 'cai_wrapper', 'wrap_array']
class cai_wrapper(pylibraft.common.ai_wrapper.ai_wrapper):
    """

        Simple wrapper around a CUDA array interface object to reduce
        boilerplate for extracting common information from the underlying
        dictionary.

    """
    def __init__(self, cai_arr):
        """

                Constructor accepts a CUDA array interface compliant array

                Parameters
                ----------
                cai_arr : CUDA array interface array

        """
def wrap_array(array):
    ...
