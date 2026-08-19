/*
 * SPDX-FileCopyrightText: Copyright (c) 2022-2023, NVIDIA CORPORATION.
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

#include <raft/core/comms.hpp>
#include <raft/core/resource/resource_types.hpp>
#include <raft/core/resources.hpp>

namespace raft::resource {
class sub_comms_resource : public resource {
 public:
  sub_comms_resource() : communicators_() {}
  void* get_resource() override { return &communicators_; }

  ~sub_comms_resource() override {}

 private:
  std::unordered_map<std::string, std::shared_ptr<comms::comms_t>> communicators_;
};

/**
 * Factory that knows how to construct a
 * specific raft::resource to populate
 * the res_t.
 */
class sub_comms_resource_factory : public resource_factory {
 public:
  resource_type get_resource_type() override { return resource_type::SUB_COMMUNICATOR; }
  resource* make_resource() override { return new sub_comms_resource(); }
};

/**
 * @defgroup resource_sub_comms Subcommunicator resource functions
 * @{
 */

inline const comms::comms_t& get_subcomm(const resources& res, std::string key)
{
  res.add_resource_factory_if_not_present<sub_comms_resource_factory>(
    resource_type::SUB_COMMUNICATOR);
  auto sub_comms =
    res.get_resource<std::unordered_map<std::string, std::shared_ptr<comms::comms_t>>>(
      resource_type::SUB_COMMUNICATOR);
  auto sub_comm = sub_comms->at(key);
  RAFT_EXPECTS(nullptr != sub_comm.get(), "ERROR: Subcommunicator was not initialized");

  return *sub_comm;
}

inline void set_subcomm(resources const& res,
                        std::string key,
                        std::shared_ptr<comms::comms_t> subcomm)
{
  res.add_resource_factory_if_not_present<sub_comms_resource_factory>(
    resource_type::SUB_COMMUNICATOR);
  auto sub_comms =
    res.get_resource<std::unordered_map<std::string, std::shared_ptr<comms::comms_t>>>(
      resource_type::SUB_COMMUNICATOR);
  sub_comms->insert(std::make_pair(key, subcomm));
}

/**
 * @}
 */

}  // namespace raft::resource
