// MIT License
//
// Copyright (c) 2025 Advanced Micro Devices, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <raft/core/copy.hpp>
#include <raft/core/device_mdarray.hpp>
#include <raft/core/device_resources.hpp>
#include <raft/core/host_mdarray.hpp>
#include <raft/linalg/dot.cuh>
#include <raft/linalg/gemv.cuh>
#include <raft/linalg/mean_squared_error.cuh>
#include <raft/random/rng.cuh>

int main()
{
    raft::device_resources dev_resources;

    // Set pool memory resource with 1 GiB initial pool size. All allocations use the same pool.
    rmm::mr::pool_memory_resource<rmm::mr::device_memory_resource> pool_mr(
        rmm::mr::get_current_device_resource(), 1024 * 1024 * 1024ull);
    rmm::mr::set_current_device_resource(&pool_mr);

    // Alternatively, one could define a pool allocator for temporary arrays (used within RAFT
    // algorithms). In that case only the internal arrays would use the pool, any other allocation
    // uses the default RMM memory resource. Here is how to change the workspace memory resource to
    // a pool with 2 GiB upper limit.
    // raft::resource::set_workspace_to_pool_resource(dev_resources, 2 * 1024 * 1024 * 1024ull);

    int n_rows = 200;
    int n_cols = 300;

    auto A = raft::make_device_matrix<float>(dev_resources, n_rows, n_cols);
    auto x = raft::make_device_vector<float>(dev_resources, n_cols);

    raft::random::RngState r(1234ULL);
    raft::random::uniform(
        dev_resources,
        r,
        raft::make_device_vector_view(A.data_handle(), A.size()),
        -1.0f,
        1.0f);
    raft::random::uniform(
        dev_resources,
        r,
        x.view(),
        -1.0f,
        1.0f);

    // matrix vector product using dot products
    auto y1 = raft::make_device_vector<float>(dev_resources, n_rows);
    for (int i = 0; i < n_rows; ++i) {
        raft::linalg::dot(
            dev_resources,
            raft::make_const_mdspan(raft::make_device_vector_view(A.data_handle() + (i * n_cols), n_cols)),
            raft::make_const_mdspan(x.view()),
            raft::make_device_scalar_view(y1.data_handle() + i));
    }

    // matrix vector product using gemv
    // gemv expects column major matrix
    auto A_cm = raft::make_device_matrix<float, int, raft::col_major>(dev_resources, n_rows, n_cols);
    raft::copy(dev_resources, A_cm.view(), A.view());
    auto y2 = raft::make_device_vector<float>(dev_resources, n_rows);

    raft::linalg::gemv(
        dev_resources,
        raft::make_const_mdspan(A_cm.view()),
        raft::make_const_mdspan(x.view()),
        y2.view());

    // compute the mean squared error between the results
    auto mse = raft::make_device_scalar<float, int>(dev_resources, 0.0f);
    raft::linalg::mean_squared_error(
        dev_resources,
        raft::make_const_mdspan(y1.view()),
        raft::make_const_mdspan(y2.view()),
        mse.view(),
        1.0f);

    // The calls to RAFT algorithms and raft::copy is asynchronous.
    // We need to sync the stream before accessing the data.
    dev_resources.sync_stream();

    // should print a very small value
    std::cout << "Mean Squared Error: " << mse(0) << "\n";

    return 0;
}
