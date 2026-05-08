/*
 * SPDX-FileCopyrightText: Copyright (c) 2022-2026, NVIDIA CORPORATION.
 * SPDX-License-Identifier: Apache-2.0
 */

// MIT License
//
// Modifications Copyright (C) 2025-2026 Advanced Micro Devices, Inc. All rights reserved.
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

#pragma once

#include <raft/core/detail/macros.hpp>
#include <raft/core/resource/cuda_stream.hpp>
#include <raft/core/resource/resource_types.hpp>
#include <raft/core/resources.hpp>

#include <rmm/exec_policy.hpp>
namespace RAFT_EXPORT raft {
namespace resource {
class thrust_policy_resource : public resource {
 public:
  thrust_policy_resource(rmm::cuda_stream_view stream_view)
    : thrust_policy_(std::make_unique<rmm::exec_policy_nosync>(stream_view))
  {
  }
  void* get_resource() override { return thrust_policy_.get(); }

  ~thrust_policy_resource() override {}

 private:
  std::unique_ptr<rmm::exec_policy_nosync> thrust_policy_;
};

/**
 * Factory that knows how to construct a
 * specific raft::resource to populate
 * the res_t.
 */
class thrust_policy_resource_factory : public resource_factory {
 public:
  thrust_policy_resource_factory(rmm::cuda_stream_view stream_view) : stream_view_(stream_view) {}
  resource_type get_resource_type() override { return resource_type::THRUST_POLICY; }
  resource* make_resource() override { return new thrust_policy_resource(stream_view_); }

 private:
  rmm::cuda_stream_view stream_view_;
};

/**
 * @defgroup resource_thrust_policy Thrust policy resource functions
 * @{
 */

/**
 * Load a thrust policy from a res (and populate it on the res if needed).
 * @param res raft res object for managing resources
 * @return thrust execution policy
 */
inline rmm::exec_policy_nosync& get_thrust_policy(resources const& res)
{
  rmm::cuda_stream_view stream = get_cuda_stream(res);
  res.add_resource_factory_if_not_present<thrust_policy_resource_factory>(
    resource_type::THRUST_POLICY, stream);
  return *res.get_resource<rmm::exec_policy_nosync>(resource_type::THRUST_POLICY);
};

/**
 * @}
 */

}  // namespace resource
}  // namespace RAFT_EXPORT raft
