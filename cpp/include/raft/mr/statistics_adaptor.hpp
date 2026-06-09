/*
 * SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
 * SPDX-License-Identifier: Apache-2.0
 */
#pragma once

#include <cuda/memory_resource>
#include <cuda/stream_ref>

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <type_traits>
#include <utility>

namespace raft::mr {

/**
 * @brief Atomic allocation counters readable from any thread without locking.
 */
struct resource_stats {
  std::atomic<std::int64_t> bytes_current{0};
  std::atomic<std::int64_t> bytes_peak{0};
  std::atomic<std::int64_t> bytes_total_allocated{0};
  std::atomic<std::int64_t> bytes_total_deallocated{0};
  std::atomic<std::int64_t> num_allocations{0};
  std::atomic<std::int64_t> num_deallocations{0};

  void record_allocate(std::int64_t bytes)
  {
    auto cur  = bytes_current.fetch_add(bytes, std::memory_order_relaxed) + bytes;
    auto peak = bytes_peak.load(std::memory_order_relaxed);
    while (cur > peak && !bytes_peak.compare_exchange_weak(peak, cur, std::memory_order_relaxed)) {}
    bytes_total_allocated.fetch_add(bytes, std::memory_order_relaxed);
    num_allocations.fetch_add(1, std::memory_order_relaxed);
  }

  void record_deallocate(std::int64_t bytes)
  {
    bytes_current.fetch_sub(bytes, std::memory_order_relaxed);
    bytes_total_deallocated.fetch_add(bytes, std::memory_order_relaxed);
    num_deallocations.fetch_add(1, std::memory_order_relaxed);
  }
};

/**
 * @brief Resource adaptor that maintains atomic allocation statistics.
 *
 * The allocations/deallocations are recorded after the fact - not recorded on exception.
 *
 * Forwards all allocations/deallocations to the upstream resource and updates
 * a shared resource_stats object.  The stats are co-owned via shared_ptr so
 * they survive type-erasure of this adaptor.
 *
 * @note Make sure to call get_stats() before type-erasing the adaptor to get the statistics.
 *
 * @tparam Upstream  Stored by value.  Use a concrete resource type for owning
 *                   semantics, or a ref type (e.g. raft::mr::host_resource_ref)
 *                   for non-owning semantics.
 */
template <typename Upstream>
class statistics_adaptor {
  Upstream upstream_;
  std::shared_ptr<resource_stats> stats_;

 public:
  // Prevent recursive concept satisfaction when Upstream is a __basic_any type (GCC C++20).
  template <typename U, std::enable_if_t<std::is_same_v<std::decay_t<U>, Upstream>, int> = 0>
  explicit statistics_adaptor(U&& upstream)
    : upstream_(std::forward<U>(upstream)), stats_(std::make_shared<resource_stats>())
  {
  }

  /**
   * @brief Get the shared resource_stats object.
   *
   * @return shared pointer to the resource_stats object
   */
  [[nodiscard]] auto get_stats() const noexcept -> std::shared_ptr<resource_stats>
  {
    return stats_;
  }

  void* allocate_sync(std::size_t bytes, std::size_t alignment = alignof(std::max_align_t))
  {
    void* ptr = upstream_.allocate_sync(bytes, alignment);
    stats_->record_allocate(static_cast<std::int64_t>(bytes));
    return ptr;
  }

  void deallocate_sync(void* ptr,
                       std::size_t bytes,
                       std::size_t alignment = alignof(std::max_align_t)) noexcept
  {
    upstream_.deallocate_sync(ptr, bytes, alignment);
    stats_->record_deallocate(static_cast<std::int64_t>(bytes));
  }

  template <typename U = Upstream, std::enable_if_t<cuda::mr::resource<U>, int> = 0>
  void* allocate(cuda::stream_ref stream,
                 std::size_t bytes,
                 std::size_t alignment = alignof(std::max_align_t))
  {
    void* ptr = upstream_.allocate(stream, bytes, alignment);
    stats_->record_allocate(static_cast<std::int64_t>(bytes));
    return ptr;
  }

  template <typename U = Upstream, std::enable_if_t<cuda::mr::resource<U>, int> = 0>
  void deallocate(cuda::stream_ref stream,
                  void* ptr,
                  std::size_t bytes,
                  std::size_t alignment = alignof(std::max_align_t)) noexcept
  {
    upstream_.deallocate(stream, ptr, bytes, alignment);
    stats_->record_deallocate(static_cast<std::int64_t>(bytes));
  }

  [[nodiscard]] bool operator==(statistics_adaptor const& other) const noexcept
  {
    return upstream_ == other.upstream_;
  }

  [[nodiscard]] bool operator!=(statistics_adaptor const& other) const noexcept
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
  friend auto constexpr get_property(statistics_adaptor const& self, Property prop) noexcept
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
    statistics_adaptor const&, cuda::mr::dynamic_accessibility_property) noexcept
  {
    return cuda::mr::__memory_accessibility_from_static_properties<
      cuda::has_property<statistics_adaptor, cuda::mr::host_accessible>,
      cuda::has_property<statistics_adaptor, cuda::mr::device_accessible>>();
  }
};

template <typename Upstream>
statistics_adaptor(Upstream) -> statistics_adaptor<Upstream>;

}  // namespace raft::mr

// Opt this adaptor out of libhipcxx's default dynamic_accessibility_property
// get_property, so only the dedicated overload above answers the query (otherwise both
// are equally viable and the call is ambiguous, breaking concept conformance).
namespace cuda::mr {
template <typename Upstream>
inline constexpr bool
  __disable_default_dynamic_accessibility_property<::raft::mr::statistics_adaptor<Upstream>> = true;
}  // namespace cuda::mr
