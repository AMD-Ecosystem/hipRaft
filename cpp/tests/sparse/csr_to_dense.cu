/*
 * Copyright (c) 2018-2024, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Modifications Copyright (c) 2024-2025 Advanced Micro Devices, Inc.
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "../test_utils.cuh"

#include <raft/core/resource/cuda_stream.hpp>
#include <raft/core/resources.hpp>
#include <raft/sparse/convert/dense.cuh>
#include <raft/sparse/detail/cusparse_wrappers.h>
#include <raft/util/cudart_utils.hpp>

#include <rmm/device_uvector.hpp>

#ifdef __HIP_PLATFORM_AMD__
#include <raft/cusparse.h>
#else
#include <cusparse_v2.h>
#endif
#include <gtest/gtest.h>

namespace raft {
namespace sparse {

using namespace raft;
using namespace raft::sparse;

template <typename value_idx, typename value_t>
struct CSRToDenseInputs {
  value_idx nrows;
  value_idx ncols;
  value_idx nnz;

  std::vector<value_idx> indptr_h;
  std::vector<value_idx> indices_h;
  std::vector<value_t> data_h;

  std::vector<value_t> out_ref_h;
};

template <typename value_idx, typename value_t>
::std::ostream& operator<<(::std::ostream& os, const CSRToDenseInputs<value_idx, value_t>& dims)
{
  return os;
}

template <typename value_idx, typename value_t>
class CSRToDenseTest : public ::testing::TestWithParam<CSRToDenseInputs<value_idx, value_t>> {
 public:
  CSRToDenseTest()
    : params(::testing::TestWithParam<CSRToDenseInputs<value_idx, value_t>>::GetParam()),
      stream(resource::get_cuda_stream(raft_handle)),
      indptr(0, stream),
      indices(0, stream),
      data(0, stream),
      out_ref(0, stream),
      out(0, stream)
  {
    indptr.resize(params.indptr_h.size(), stream);
    indices.resize(params.indices_h.size(), stream);
    data.resize(params.data_h.size(), stream);
    out_ref.resize(params.out_ref_h.size(), stream);
    out.resize(params.out_ref_h.size(), stream);
  }

 protected:
  void make_data()
  {
    std::vector<value_idx> indptr_h  = params.indptr_h;
    std::vector<value_idx> indices_h = params.indices_h;
    std::vector<value_t> data_h      = params.data_h;

    update_device(indptr.data(), indptr_h.data(), indptr_h.size(), stream);
    update_device(indices.data(), indices_h.data(), indices_h.size(), stream);
    update_device(data.data(), data_h.data(), data_h.size(), stream);

    std::vector<value_t> out_ref_h = params.out_ref_h;

    update_device(out_ref.data(), out_ref_h.data(), out_ref_h.size(), stream);
    RAFT_CUDA_TRY(cudaStreamSynchronize(stream));
  }

  void SetUp() override
  {
    RAFT_CUSPARSE_TRY(cusparseCreate(&handle));

    make_data();

    convert::csr_to_dense(handle,
                          params.nrows,
                          params.ncols,
                          params.nnz,
                          indptr.data(),
                          indices.data(),
                          data.data(),
                          params.nrows,
                          out.data(),
                          stream,
                          true);

    RAFT_CUDA_TRY(cudaStreamSynchronize(stream));
    RAFT_CUSPARSE_TRY(cusparseDestroy(handle));
  }

  void compare()
  {
    ASSERT_TRUE(
      devArrMatch(out.data(), out_ref.data(), params.out_ref_h.size(), Compare<value_t>()));
  }

 protected:
  raft::resources raft_handle;
  cudaStream_t stream;

  cusparseHandle_t handle;

  // input data
  rmm::device_uvector<value_idx> indptr, indices;
  rmm::device_uvector<value_t> data;

  // output data
  rmm::device_uvector<value_t> out;

  // expected output data
  rmm::device_uvector<value_t> out_ref;

  CSRToDenseInputs<value_idx, value_t> params;
};

const std::vector<CSRToDenseInputs<int, float>> inputs_i32_f = {
  {4,
   4,
   8,
   {0, 2, 4, 6, 8},
   {0, 1, 2, 3, 0, 1, 2, 3},  // indices
   {1.0f, 3.0f, 1.0f, 5.0f, 50.0f, 28.0f, 16.0f, 2.0f},
   {1.0f,
    3.0f,
    0.0f,
    0.0f,
    0.0f,
    0.0f,
    1.0f,
    5.0f,
    50.0f,
    28.0f,
    0.0f,
    0.0f,
    0.0f,
    0.0f,
    16.0f,
    2.0f}},
};
typedef CSRToDenseTest<int, float> CSRToDenseTestF;
TEST_P(CSRToDenseTestF, Result) { compare(); }
INSTANTIATE_TEST_CASE_P(CSRToDenseTest, CSRToDenseTestF, ::testing::ValuesIn(inputs_i32_f));

};  // end namespace sparse
};  // end namespace raft
