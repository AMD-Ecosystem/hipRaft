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
#include <raft/core/resource/thrust_policy.hpp>
#include <raft/random/make_blobs.cuh>

#include <thrust/fill.h>

#include <iostream>
#include <random>
#include <string_view>

template <typename ViewT1, typename ViewT2, typename ViewT3>
__global__ void map_blobs(
    const ViewT1 blobs,
    const ViewT2 labels,
    ViewT3 map,
    float offset,
    float x_scale,
    float y_scale)
{
    int sample_idx = (blockIdx.x * blockDim.x) + threadIdx.x;
    if (sample_idx >= blobs.extent(0)) {
        return;
    }
    auto map_r = static_cast<int>((blobs(sample_idx, 0) + offset) * y_scale);
    auto map_c = static_cast<int>((blobs(sample_idx, 1) + offset) * x_scale);
    if (map_r >= 0 && map_r < map.extent(0) && map_c >= 0 && map_c < map.extent(1)) {
        map(map_r, map_c) = '0' + labels[sample_idx];
    }
}

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

    int n_samples = 200;
    int n_features = 2;

    auto blobs = raft::make_device_matrix<float>(dev_resources, n_samples, n_features);
    auto labels = raft::make_device_vector<int>(dev_resources, n_samples);

    float map_min = -10.0f;
    float map_max = 10.0f;

    std::uint64_t seed = std::random_device{}();
    std::cout << "seed: " << seed << "\n";

    raft::random::make_blobs(
        dev_resources,      // handle
        blobs.view(),       // out
        labels.view(),      // labels
        5,                  // n_clusters
        {std::nullopt},     // centers
        {std::nullopt},     // cluster_std
        1.0f,               // cluster_std_scalar
        true,               // shuffle
        map_min,            // center_box_min
        map_max,            // center_box_max
        seed,               // seed
        raft::random::GenPC // type
    );

    // Plot the blobs:
    //--------------------------------------------------------------------------
    int n_map_cols = 41;
    int n_map_rows = 21;
    auto map = raft::make_device_matrix<char>(dev_resources, n_map_rows, n_map_cols);
    thrust::fill_n(
        raft::resource::get_thrust_policy(dev_resources),
        map.data_handle(),
        map.size(),
        '.');

    auto x_scale = static_cast<float>(n_map_cols - 1) / (map_max - map_min);
    auto y_scale = static_cast<float>(n_map_rows - 1) / (map_max - map_min);

    int n_threads_per_block = 256;
    int n_blocks = (n_samples + n_threads_per_block - 1) / n_threads_per_block;
    map_blobs<<<n_blocks, n_threads_per_block, 0, dev_resources.get_stream().value()>>>(
        blobs.view(),
        labels.view(),
        map.view(),
        -map_min,
        x_scale,
        y_scale);

    auto map_host = raft::make_host_matrix<char>(n_map_rows, n_map_cols);
    raft::copy(dev_resources, map_host.view(), map.view());

    // The calls to RAFT algorithms and raft::copy is asynchronous.
    // We need to sync the stream before accessing the data.
    dev_resources.sync_stream();

    for (int i = 0; i < n_map_rows; ++i) {
        auto row_str = std::string_view(map_host.data_handle() + (i * n_map_cols), n_map_cols);
        std::cout << row_str << "\n";
    }

    return 0;
}
