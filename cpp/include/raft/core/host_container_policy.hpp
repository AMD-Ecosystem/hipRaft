/*
 * SPDX-FileCopyrightText: Copyright (c) 2019 Sandia Corporation
 * SPDX-FileCopyrightText: Copyright (c) 2022-2026, NVIDIA CORPORATION.
 * SPDX-License-Identifier: Apache-2.0 AND BSD-3-Clause
 */

// MIT License
//
// Modifications Copyright (C) 2024-2026 Advanced Micro Devices, Inc. All rights reserved.
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

/*
 * Copyright (2019) Sandia Corporation
 *
 * The source code is licensed under the 3-clause BSD license found in the LICENSE file
 * thirdparty/LICENSES/mdarray.license
 */

#pragma once

#include <raft/core/detail/macros.hpp>
#include <raft/core/mdspan_types.hpp>
#include <raft/core/resources.hpp>
#include <raft/mr/host_memory_resource.hpp>

namespace RAFT_EXPORT raft {

/**
 * @brief A container backed by a host-accessible cuda::mr::synchronous_resource.
 *
 * @tparam T element type
 * @tparam MR a type satisfying cuda::mr::synchronous_resource_with<cuda::mr::host_accessible>
 */
template <typename T, typename MR>
#ifdef __cpp_concepts
requires cuda::mr::synchronous_resource_with<MR, cuda::mr::host_accessible>
#endif
  struct host_container {
  static_assert(cuda::mr::synchronous_resource_with<MR, cuda::mr::host_accessible>,
                "MR must be a host-accessible synchronous resource");
  using value_type = std::remove_cv_t<T>;
  using size_type  = std::size_t;

  using reference       = value_type&;
  using const_reference = value_type const&;

  using pointer       = value_type*;
  using const_pointer = value_type const*;

  using iterator       = pointer;
  using const_iterator = const_pointer;

 private:
  MR mr_;
  size_type bytesize_ = 0;
  value_type* data_   = nullptr;

 public:
  host_container(size_type count,
                 MR mr)  // NB: pass by value, as we expect a resource_ref anyway
    : mr_(std::move(mr)),
      bytesize_(sizeof(value_type) * count),
      data_(bytesize_ > 0 ? static_cast<pointer>(mr_.allocate_sync(bytesize_)) : nullptr)
  {
  }

  ~host_container() noexcept
  {
    if (bytesize_ > 0 && data_ != nullptr) { mr_.deallocate_sync(data_, bytesize_); }
  }

  host_container(host_container&& other) noexcept
    : mr_{std::move(other.mr_)},
      bytesize_{std::exchange(other.bytesize_, 0)},
      data_{std::exchange(other.data_, nullptr)}
  {
  }
  host_container& operator=(host_container&& other) noexcept
  {
    std::swap(this->mr_, other.mr_);
    std::swap(this->bytesize_, other.bytesize_);
    std::swap(this->data_, other.data_);
    return *this;
  }
  host_container(host_container const&) = delete;  // Copying disallowed: one array one owner
  host_container& operator=(host_container const&) = delete;

  /**
   * @brief Index operator that returns a reference to the actual data.
   */
  template <typename Index>
  auto operator[](Index i) noexcept -> reference
  {
    return data_[i];
  }
  /**
   * @brief Index operator that returns a reference to the actual data.
   */
  template <typename Index>
  auto operator[](Index i) const noexcept -> const_reference
  {
    return data_[i];
  }

  void resize(size_type count)
  {
    auto cur_count = bytesize_ / sizeof(value_type);
    if (count <= cur_count) { return; }
    host_container new_container{count, mr_};
    std::copy(data_, data_ + cur_count, new_container.data_);
    *this = std::move(new_container);
  }

  [[nodiscard]] auto data() noexcept -> pointer { return data_; }
  [[nodiscard]] auto data() const noexcept -> const_pointer { return data_; }
};

/**
 * @brief Container policy for host mdarray.
 *
 * Defaults to raft::mr::get_default_host_resource().
 */
template <typename ElementType>
class host_container_policy {
 public:
  using element_type          = ElementType;
  using container_type        = host_container<element_type, raft::mr::host_resource_ref>;
  using pointer               = typename container_type::pointer;
  using const_pointer         = typename container_type::const_pointer;
  using reference             = typename container_type::reference;
  using const_reference       = typename container_type::const_reference;
  using accessor_policy       = cuda::std::default_accessor<element_type>;
  using const_accessor_policy = cuda::std::default_accessor<element_type const>;

  host_container_policy() = default;
  explicit host_container_policy(raft::mr::host_resource_ref ref) noexcept : ref_(ref) {}

  auto create(raft::resources const&, size_t n) -> container_type
  {
    return container_type(n, ref_);
  }

  [[nodiscard]] constexpr auto access(container_type& c, size_t n) const noexcept -> reference
  {
    return c[n];
  }
  [[nodiscard]] constexpr auto access(container_type const& c, size_t n) const noexcept
    -> const_reference
  {
    return c[n];
  }

  [[nodiscard]] auto make_accessor_policy() noexcept { return accessor_policy{}; }
  [[nodiscard]] auto make_accessor_policy() const noexcept { return const_accessor_policy{}; }

 private:
  raft::mr::host_resource_ref ref_ = raft::mr::get_default_host_resource();
};

// NOTE(HIP/AMD, 26.04): An AMD workaround alias
//   template <typename T> using host_vector_policy_default_allocator = host_vector_policy<T>;
// used to live here, to feed a single-nested-param template-template parameter
// (`template <typename T> typename ContainerPolicy`) when the old `host_vector_policy`
// had two params. Upstream #2835 renamed it to the single-param `host_container_policy`
// (above) and updated host_coo_matrix.hpp / host_csr_matrix.hpp / host_mdarray.hpp to
// default to it directly, so the alias became dead code pointing at a deleted symbol and
// was removed. REVISIT: if a future change reintroduces a multi-param host policy and a
// template-template-arg mismatch resurfaces (clang + rocthrust, -frelaxed-template-template-args
// incompatible), restore a single-param alias like:
//   template <typename T> using host_vector_policy_default_allocator = host_container_policy<T>;
// and use it as the ContainerPolicy default in the host matrix headers.

}  // namespace RAFT_EXPORT raft
