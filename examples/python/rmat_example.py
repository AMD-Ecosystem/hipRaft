# MIT License
#
# Copyright (c) 2025 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import cupy
import pylibraft.common as raft_common
import pylibraft.random as raft_random

n_edges = 500
r_scale = 8
c_scale = 7

cupy.random.seed(1234)
theta = cupy.random.random_sample(
    (max(r_scale, c_scale), 4), dtype=cupy.float32
)
# normalize probabilities at each level
theta[theta.sum(axis=1) == 0.0] = cupy.full(4, 0.25, dtype=cupy.float32)
theta /= theta.sum(axis=1, keepdims=True)

# rmat expects a flat array
theta = theta.ravel()

out = cupy.empty((n_edges, 2), dtype=cupy.int32)

# A single RAFT handle can optionally be reused across
# pylibraft functions.
handle = raft_common.Handle()

raft_random.rmat(out, theta, r_scale, c_scale, handle=handle)

# pylibraft functions are often asynchronous so the
# handle needs to be explicitly synchronized
handle.sync()

out = out.get()

num_duplicates = 0
num_self_loops = 0
adj_list = dict()
for src, dst in out:
    if src == dst:
        num_self_loops += 1
        continue
    if src not in adj_list:
        adj_list[src] = {dst}
    elif dst in adj_list[src]:
        num_duplicates += 1
    else:
        adj_list[src].add(dst)

print(f"number of self-loops: {num_self_loops}")
print(f"number of duplicates: {num_duplicates}")

print("Graph Adjacency List:")
for node, nbrs in adj_list.items():
    print(f"{int(node)} : { {int(n) for n in nbrs} }")
