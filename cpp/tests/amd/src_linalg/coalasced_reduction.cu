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

/*
 * Copyright (c) 2022-2023, NVIDIA CORPORATION.
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

#include <raft/core/operators.hpp>
#include <raft/core/resource/cuda_stream.hpp>
#include <raft/linalg/detail/coalesced_reduction-inl.cuh>
#include <raft/random/rng.cuh>
#include <raft/util/cuda_utils.cuh>
#include <raft/util/cudart_utils.hpp>

#include <gtest/gtest.h>
#include <linalg/reduce.cuh>
#include <test_utils.cuh>

namespace raft {
namespace linalg {

template <typename InT, typename OutT, typename IdxT>
struct CoalescedReductionDetailInputs {
  OutT tolerance;
  IdxT rows, cols;
  unsigned long long seed;
};

template <typename InT, typename OutT, typename IdxT>
::std::ostream& operator<<(::std::ostream& os,
                           const CoalescedReductionDetailInputs<InT, OutT, IdxT>& dims)
{
  return os << "{ tol: " << dims.tolerance << ", rows: " << dims.rows << ", cols: " << dims.cols
            << ", seed: " << dims.seed << " }";
}

template <typename InT,
          typename OutT,
          typename IdxT,
          typename MainOp,
          typename ReduceOp,
          typename FinalOp>
void coalescedReductionDetailLaunch(OutT* dots,
                                    const InT* data,
                                    IdxT D,
                                    IdxT N,
                                    OutT init,
                                    cudaStream_t stream,
                                    bool inplace,
                                    MainOp main_op,
                                    ReduceOp reduce_op,
                                    FinalOp final_op)
{
  raft::linalg::detail::coalescedReduction(
    dots, data, D, N, init, stream, inplace, main_op, reduce_op, final_op);
}

template <typename InT,
          typename OutT,
          typename IdxT,
          typename MainOp,
          typename ReduceOp,
          typename FinalOp>
class CoalescedReductionDetailTest
  : public ::testing::TestWithParam<CoalescedReductionDetailInputs<InT, OutT, IdxT>> {
 public:
  CoalescedReductionDetailTest()
    : params(::testing::TestWithParam<CoalescedReductionDetailInputs<InT, OutT, IdxT>>::GetParam()),
      stream(resource::get_cuda_stream(handle)),
      data(params.rows * params.cols, stream),
      dots_exp(params.rows, stream),
      dots_act(params.rows, stream)
  {
  }

 protected:
  void SetUp() override
  {
    raft::random::RngState r(params.seed);
    int len = params.rows * params.cols;
    // Fill input data uniformly between -1 and 1.
    uniform(handle, r, data.data(), len, InT(-1.0), InT(1.0));

    naiveCoalescedReduction(dots_exp.data(),
                            data.data(),
                            params.cols,
                            params.rows,
                            stream,
                            OutT(0),
                            false,
                            main_op,
                            reduce_op,
                            final_op);
    naiveCoalescedReduction(dots_exp.data(),
                            data.data(),
                            params.cols,
                            params.rows,
                            stream,
                            OutT(0),
                            true,
                            main_op,
                            reduce_op,
                            final_op);

    coalescedReductionDetailLaunch(dots_act.data(),
                                   data.data(),
                                   params.cols,
                                   params.rows,
                                   OutT(0),
                                   stream,
                                   false,
                                   main_op,
                                   reduce_op,
                                   final_op);
    coalescedReductionDetailLaunch(dots_act.data(),
                                   data.data(),
                                   params.cols,
                                   params.rows,
                                   OutT(0),
                                   stream,
                                   true,
                                   main_op,
                                   reduce_op,
                                   final_op);

    resource::sync_stream(handle, stream);
  }

 protected:
  raft::resources handle;
  cudaStream_t stream;
  CoalescedReductionDetailInputs<InT, OutT, IdxT> params;
  rmm::device_uvector<InT> data;
  rmm::device_uvector<OutT> dots_exp;
  rmm::device_uvector<OutT> dots_act;

  MainOp main_op;
  ReduceOp reduce_op;
  FinalOp final_op;
};

typedef CoalescedReductionDetailTest<double,
                                     double,
                                     int,
                                     raft::identity_op,
                                     raft::min_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_D1;
TEST_P(CoalescedReductionDetailTest_D1, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<double>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<double, double, int>> inputs_d1 = {
  {0.000000001, 50, 2, 1234ULL}, {0.000000001, 50, 7, 1234ULL}, {0.000000001, 10000, 55, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_D1,
                        CoalescedReductionDetailTest_D1,
                        ::testing::ValuesIn(inputs_d1));

typedef CoalescedReductionDetailTest<double,
                                     double,
                                     int,
                                     raft::sq_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_D2;
TEST_P(CoalescedReductionDetailTest_D2, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<double>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<double, double, int>> inputs_d2 = {
  {0.000000001, 50, 3, 1234ULL},
  {0.000000001, 10000, 20, 1234ULL},
  {0.000000001, 10000, 270, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_D2,
                        CoalescedReductionDetailTest_D2,
                        ::testing::ValuesIn(inputs_d2));

typedef CoalescedReductionDetailTest<double, double, int, raft::sq_op, raft::add_op, raft::sqrt_op>
  CoalescedReductionDetailTest_D3;
TEST_P(CoalescedReductionDetailTest_D3, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<double>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<double, double, int>> inputs_d3 = {
  {0.000000001, 50, 9, 1234ULL},
  {0.000000001, 10000, 55, 1234ULL},
  {0.000000001, 10000, 100, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_D3,
                        CoalescedReductionDetailTest_D3,
                        ::testing::ValuesIn(inputs_d3));

typedef CoalescedReductionDetailTest<double,
                                     double,
                                     int,
                                     raft::abs_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_D4;
TEST_P(CoalescedReductionDetailTest_D4, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<double>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<double, double, int>> inputs_d4 = {
  {0.000000001, 50, 4, 1234ULL}, {0.000000001, 100, 15, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_D4,
                        CoalescedReductionDetailTest_D4,
                        ::testing::ValuesIn(inputs_d4));

typedef CoalescedReductionDetailTest<double,
                                     double,
                                     int,
                                     raft::abs_op,
                                     raft::max_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_D5;
TEST_P(CoalescedReductionDetailTest_D5, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<double>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<double, double, int>> inputs_d5 = {
  {0.000000001, 50, 6, 1234ULL}, {0.000000001, 100, 20, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_D5,
                        CoalescedReductionDetailTest_D5,
                        ::testing::ValuesIn(inputs_d5));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     int,
                                     raft::identity_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F1;
TEST_P(CoalescedReductionDetailTest_F1, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, int>> inputs_f1 = {
  {0.000002f, 50, 2, 1234ULL}, {0.000002f, 50, 7, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F1,
                        CoalescedReductionDetailTest_F1,
                        ::testing::ValuesIn(inputs_f1));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     size_t,
                                     raft::abs_op,
                                     raft::add_op,
                                     raft::sqrt_op>
  CoalescedReductionDetailTest_F2;
TEST_P(CoalescedReductionDetailTest_F2, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, size_t>> inputs_f2 = {
  {0.000002f, 50, 3, 1234ULL}, {0.000002f, 100, 20, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F2,
                        CoalescedReductionDetailTest_F2,
                        ::testing::ValuesIn(inputs_f2));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     int,
                                     raft::abs_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F3;
TEST_P(CoalescedReductionDetailTest_F3, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, int>> inputs_f3 = {
  {0.000002f, 50, 4, 1234ULL}, {0.000002f, 200, 10, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F3,
                        CoalescedReductionDetailTest_F3,
                        ::testing::ValuesIn(inputs_f3));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     int,
                                     raft::identity_op,
                                     raft::min_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F4;
TEST_P(CoalescedReductionDetailTest_F4, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, int>> inputs_f4 = {
  {0.000002f, 50, 5, 1234ULL}, {0.000002f, 100, 15, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F4,
                        CoalescedReductionDetailTest_F4,
                        ::testing::ValuesIn(inputs_f4));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     int,
                                     raft::sq_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F5;
TEST_P(CoalescedReductionDetailTest_F5, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, int>> inputs_f5 = {
  {0.000002f, 50, 6, 1234ULL}, {0.000002f, 200, 12, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F5,
                        CoalescedReductionDetailTest_F5,
                        ::testing::ValuesIn(inputs_f5));

typedef CoalescedReductionDetailTest<float, float, int, raft::sq_op, raft::add_op, raft::sqrt_op>
  CoalescedReductionDetailTest_F6;
TEST_P(CoalescedReductionDetailTest_F6, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, int>> inputs_f6 = {
  {0.000002f, 50, 7, 1234ULL}, {0.000002f, 200, 14, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F6,
                        CoalescedReductionDetailTest_F6,
                        ::testing::ValuesIn(inputs_f6));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     long,
                                     raft::sq_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F7;
TEST_P(CoalescedReductionDetailTest_F7, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, long>> inputs_f7 = {
  {0.000002f, 50, 8, 1234ULL}, {0.000002f, 100, 16, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F7,
                        CoalescedReductionDetailTest_F7,
                        ::testing::ValuesIn(inputs_f7));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     size_t,
                                     raft::identity_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F8;
TEST_P(CoalescedReductionDetailTest_F8, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, size_t>> inputs_f8 = {
  {0.000002f, 50, 9, 1234ULL}, {0.000002f, 100, 18, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F8,
                        CoalescedReductionDetailTest_F8,
                        ::testing::ValuesIn(inputs_f8));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     size_t,
                                     raft::sq_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F9;
TEST_P(CoalescedReductionDetailTest_F9, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, size_t>> inputs_f9 = {
  {0.000002f, 50, 10, 1234ULL}, {0.000002f, 100, 20, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F9,
                        CoalescedReductionDetailTest_F9,
                        ::testing::ValuesIn(inputs_f9));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     size_t,
                                     raft::abs_op,
                                     raft::max_op,
                                     raft::sqrt_op>
  CoalescedReductionDetailTest_F10;
TEST_P(CoalescedReductionDetailTest_F10, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, size_t>> inputs_f10 = {
  {0.000002f, 50, 11, 1234ULL}, {0.000002f, 100, 22, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F10,
                        CoalescedReductionDetailTest_F10,
                        ::testing::ValuesIn(inputs_f10));

typedef CoalescedReductionDetailTest<float, float, size_t, raft::sq_op, raft::add_op, raft::sqrt_op>
  CoalescedReductionDetailTest_F11;
TEST_P(CoalescedReductionDetailTest_F11, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, size_t>> inputs_f11 = {
  {0.000002f, 50, 12, 1234ULL}, {0.000002f, 100, 24, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F11,
                        CoalescedReductionDetailTest_F11,
                        ::testing::ValuesIn(inputs_f11));

typedef CoalescedReductionDetailTest<float,
                                     float,
                                     unsigned int,
                                     raft::sq_op,
                                     raft::add_op,
                                     raft::identity_op>
  CoalescedReductionDetailTest_F12;
TEST_P(CoalescedReductionDetailTest_F12, Result)
{
  ASSERT_TRUE(raft::devArrMatch(dots_exp.data(),
                                dots_act.data(),
                                params.rows,
                                raft::CompareApprox<float>(params.tolerance),
                                stream));
}
const std::vector<CoalescedReductionDetailInputs<float, float, unsigned int>> inputs_f12 = {
  {0.000002f, 50, 3, 1234ULL}, {0.000002f, 100, 6, 1234ULL}};
INSTANTIATE_TEST_CASE_P(CoalescedReductionDetailTests_F12,
                        CoalescedReductionDetailTest_F12,
                        ::testing::ValuesIn(inputs_f12));

}  // end namespace linalg
}  // end namespace raft
