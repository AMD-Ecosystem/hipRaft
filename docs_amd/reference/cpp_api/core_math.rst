Mathematical Functions
======================

.. role:: py(code)
   :language: c++
   :class: highlight


The math functions APIs guarantee both HIP and CPU compatibility, making it more straightforward to write `__host__ __device__` functions without being concerned whether the underlying intrinsics will build and work.

``#include <raft/core/math.hpp>``

namespace *raft::core*

.. doxygengroup:: math_functions
    :project: RAFT
    :members:
    :content-only:
