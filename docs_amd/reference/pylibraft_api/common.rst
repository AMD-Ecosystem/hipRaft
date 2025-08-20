Common
======

This page provides `pylibraft` class references for the publicly-exposed elements of the `pylibraft.common` package.


.. role:: py(code)
   :language: python
   :class: highlight


Basic Vocabulary
################

.. autoapiclass:: pylibraft.common.DeviceResources
    :members:

.. autoapiclass:: pylibraft.common.Stream
    :members:

.. autoapiclass:: pylibraft.common.device_ndarray
    :members:

Interruptible
#############

.. autoapifunction:: pylibraft.common.interruptible.cuda_interruptible

.. autoapifunction:: pylibraft.common.interruptible.synchronize

.. autoapifunction:: pylibraft.common.interruptible.cuda_yield


CUDA Array Interface Helpers
############################

.. autoapiclass:: pylibraft.common.cai_wrapper.cai_wrapper
    :members:
