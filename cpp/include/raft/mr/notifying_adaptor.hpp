/*
 * SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
 * SPDX-License-Identifier: Apache-2.0
 */

// MIT License
//
// Modifications Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
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

#include <cuda/memory_resource>
#include <cuda/std/atomic>
#include <cuda/stream_ref>

#include <cstddef>
#include <memory>
#include <type_traits>
#include <utility>

namespace raft::mr {

/**
 * @brief A simple notifier that can be used to signal that one or more allocations/deallocations
 * have occurred.
 */
class notifier {
 private:
  /**
   * @brief Activity flag.
   *
   * Note, the meaning is somewhat inverted:
   * - TRUE (flag is set) means "no allocations/deallocations have occurred"
   * - FALSE (flag is clear) means "one or more allocations/deallocations have occurred"
   *
   * This is hidden behind notify() and wait() to avoid confusion.
   */
  // NB: using `cuda::std` in place of `std`,
  // because this may happen to be included in pre-C++20 code downstream.
  cuda::std::atomic_flag flag_;

 public:
  notifier() noexcept { flag_.test_and_set(cuda::std::memory_order_relaxed); }

  /**
   * @brief Change the state to "one or more allocations/deallocations have occurred".
   *        Then wake up one waiting thread.
   */
  void notify() noexcept
  {
    flag_.clear(cuda::std::memory_order_release);
    flag_.notify_one();
  }

  /**
   * @brief Wait for the state to be "one or more allocations/deallocations have occurred" then
   * reset it "no allocations/deallocations have occurred".
   *
   */
  void wait() noexcept
  {
    flag_.wait(true, cuda::std::memory_order_acquire);
    flag_.test_and_set(cuda::std::memory_order_relaxed);
  }
};

/**
 * @brief Resource adaptor that signals an external notifier on every allocation
 *        or deallocation.
 *
 * Forwards all calls to the upstream resource, then calls notifier::notify().
 * A separate consumer (e.g. resource_monitor) can call notifier::wait() to
 * block until activity occurs.
 *
 * @tparam Upstream  Stored by value.  Use a concrete resource type for owning
 *                   semantics, or a ref type for non-owning semantics.
 */
template <typename Upstream>
class notifying_adaptor {
  Upstream upstream_;
  std::shared_ptr<notifier> notifier_;

 public:
  /**
   * @brief Construct a new notifying adaptor.
   *
   * @param upstream An upstream resource or reference to wrap.
   * @param notifier A shared notifier to use (pass it to a consumer as well).
   */
  notifying_adaptor(Upstream upstream, std::shared_ptr<notifier> notifier)
    : upstream_(std::move(upstream)), notifier_(std::move(notifier))
  {
  }

  /**
   * @brief Get the shared notifier object.
   *
   * @return shared pointer to the notifier object
   */
  [[nodiscard]] auto get_notifier() const noexcept -> std::shared_ptr<notifier>
  {
    return notifier_;
  }

  void* allocate_sync(std::size_t bytes, std::size_t alignment = alignof(std::max_align_t))
  {
    void* ptr = upstream_.allocate_sync(bytes, alignment);
    notifier_->notify();
    return ptr;
  }

  void deallocate_sync(void* ptr,
                       std::size_t bytes,
                       std::size_t alignment = alignof(std::max_align_t)) noexcept
  {
    upstream_.deallocate_sync(ptr, bytes, alignment);
    notifier_->notify();
  }

  template <typename U = Upstream, std::enable_if_t<cuda::mr::resource<U>, int> = 0>
  void* allocate(cuda::stream_ref stream,
                 std::size_t bytes,
                 std::size_t alignment = alignof(std::max_align_t))
  {
    void* ptr = upstream_.allocate(stream, bytes, alignment);
    notifier_->notify();
    return ptr;
  }

  template <typename U = Upstream, std::enable_if_t<cuda::mr::resource<U>, int> = 0>
  void deallocate(cuda::stream_ref stream,
                  void* ptr,
                  std::size_t bytes,
                  std::size_t alignment = alignof(std::max_align_t)) noexcept
  {
    upstream_.deallocate(stream, ptr, bytes, alignment);
    notifier_->notify();
  }

  [[nodiscard]] bool operator==(notifying_adaptor const& other) const noexcept
  {
    return upstream_ == other.upstream_;
  }

  [[nodiscard]] bool operator!=(notifying_adaptor const& other) const noexcept
  {
    return !(*this == other);
  }

  [[nodiscard]] auto upstream_resource() noexcept -> Upstream& { return upstream_; }
  [[nodiscard]] auto upstream_resource() const noexcept -> Upstream const& { return upstream_; }

  /**
   * @brief Forwards a (non-dynamic) property query to the wrapped upstream resource.
   *
   * This SFINAE-constrained friend mirrors RMM's cccl_async_resource_ref pattern: it
   * participates only for properties the upstream actually has, and forwards the static
   * accessibility properties (host_accessible / device_accessible) to the upstream.
   *
   * We deliberately do NOT inherit cuda::forward_property: that base injects its own
   * get_property(..., dynamic_accessibility_property) overload that collides with
   * libhipcxx's default get_property for that property (this adaptor is not in
   * __disable_default_dynamic_accessibility_property), making the query ambiguous and
   * causing the adaptor to fail the cuda::mr::resource_ref / any_resource concept checks.
   *
   * dynamic_accessibility_property is handled by the dedicated overload below instead of
   * forwarding, because in this libhipcxx/RMM pairing the upstream resource_ref wrappers
   * do not themselves answer that query unambiguously; we derive it from the (forwarded)
   * static accessibility properties exactly as libhipcxx's own default does.
   */
  template <
    typename Property,
    std::enable_if_t<!std::is_same_v<Property, cuda::mr::dynamic_accessibility_property>, int> = 0>
  friend auto constexpr get_property(notifying_adaptor const& self, Property prop) noexcept
    -> decltype(get_property(std::declval<Upstream const&>(), prop))
  {
    return get_property(self.upstream_, prop);
  }

  /**
   * @brief Answers the dynamic accessibility query from the forwarded static properties.
   *
   * Mirrors libhipcxx's default implementation
   * (cuda::mr::get_property(.., dynamic_accessibility_property)) but is anchored on this
   * adaptor type so it is found unambiguously (the libhipcxx default is disabled for this
   * type via the __disable_default_dynamic_accessibility_property specialization below).
   */
  friend constexpr cuda::mr::__memory_accessibility get_property(
    notifying_adaptor const&, cuda::mr::dynamic_accessibility_property) noexcept
  {
    return cuda::mr::__memory_accessibility_from_static_properties<
      cuda::has_property<notifying_adaptor, cuda::mr::host_accessible>,
      cuda::has_property<notifying_adaptor, cuda::mr::device_accessible>>();
  }
};

}  // namespace raft::mr

// Opt this adaptor out of libhipcxx's default dynamic_accessibility_property
// get_property, so only the dedicated overload above answers the query (otherwise both
// are equally viable and the call is ambiguous, breaking concept conformance).
namespace cuda::mr {
template <typename Upstream>
inline constexpr bool
  __disable_default_dynamic_accessibility_property<::raft::mr::notifying_adaptor<Upstream>> = true;
}  // namespace cuda::mr
