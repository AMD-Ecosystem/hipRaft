/*
 * SPDX-FileCopyrightText: Copyright (c) 2024, NVIDIA CORPORATION.
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

#include <raft/core/resource/resource_types.hpp>
#include <raft/core/resources.hpp>

#include <algorithm>
#include <memory>
#include <typeindex>

namespace raft::resource {

class custom_resource : public resource {
 public:
  custom_resource()                    = default;
  ~custom_resource() noexcept override = default;
  auto get_resource() -> void* override { return this; }

  template <typename ResourceT>
  auto load() -> ResourceT*
  {
    std::lock_guard<std::mutex> _(lock_);
    auto key = std::type_index{typeid(ResourceT)};
    auto pos = std::lower_bound(store_.begin(), store_.end(), kv{key, {nullptr}});
    if ((pos != store_.end()) && std::get<0>(*pos) == key) {
      return reinterpret_cast<ResourceT*>(std::get<1>(*pos).get());
    }
    auto store_ptr = new ResourceT{};
    store_.insert(pos, kv{key, std::shared_ptr<void>(store_ptr, [](void* ptr) {
                            delete reinterpret_cast<ResourceT*>(ptr);
                          })});
    return store_ptr;
  }

 private:
  using kv = std::tuple<std::type_index, std::shared_ptr<void>>;
  std::mutex lock_{};
  std::vector<kv> store_{};
};

/** Factory that knows how to construct a specific raft::resource to populate the res_t. */
class custom_resource_factory : public resource_factory {
 public:
  auto get_resource_type() -> resource_type override { return resource_type::CUSTOM; }
  auto make_resource() -> resource* override { return new custom_resource(); }
};

/**
 * @defgroup resource_custom custom resource functions
 * @{
 */

/**
 * Get the custom default-constructible resource if it exists, create it otherwise.
 *
 * Note: in contrast to the other, hard-coded resources, there's no information about the custom
 * resources at compile time. Hence, custom resources are kept in a hashmap and looked-up at
 * runtime. This leads to slightly slower access times.
 *
 * @tparam ResourceT the type of the resource; it must be complete and default-constructible.
 *
 * @param[in] res the raft resources object
 * @return a pointer to the custom resource.
 */
template <typename ResourceT>
auto get_custom_resource(resources const& res) -> ResourceT*
{
  static_assert(std::is_default_constructible_v<ResourceT>);
  res.add_resource_factory_if_not_present<custom_resource_factory>(resource_type::CUSTOM);
  return res.get_resource<custom_resource>(resource_type::CUSTOM)->load<ResourceT>();
};

/**
 * @}
 */

}  // namespace raft::resource
