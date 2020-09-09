#include "stencil/translate.cuh"

#include "stencil/copy.cuh"
#include "stencil/cuda_runtime.hpp"
#include "stencil/logging.hpp"

#ifdef STENCIL_USE_CUDA_GRAPH
#endif

Translate::Translate() {}

void Translate::prepare(const std::vector<Params> &params) {

  LOG_SPEW("params.size()=" << params.size());

  // convert all Params into individual 3D copies
  for (const Params &ps : params) {
    LOG_SPEW("ps.n=" << ps.n);
    assert(ps.dsts);
    assert(ps.srcs);
    assert(ps.elemSizes);
    for (int64_t i = 0; i < ps.n; ++i) {
      Param p(ps.dsts[i], ps.dstPos, ps.srcs[i], ps.srcPos, ps.extent, ps.elemSizes[i]);
      params_.push_back(p);
    }
  }

  // TODO: if cudagraph, record launch here
}

void Translate::async(cudaStream_t stream) {
  launch_all(stream);
  // TODO: if cuda graph, replay here
}

void Translate::launch_all(cudaStream_t stream) {
  for (const Param &p : params_) {
    memcpy_3d_async(p, stream);
  }
}

void Translate::memcpy_3d_async(const Param &param, cudaStream_t stream) {
  cudaMemcpy3DParms p = {};

  const uint64_t es = param.elemSize;

  // "offset into the src/dst objs in units of unsigned char"
  p.srcPos = make_cudaPos(param.srcPos.x * es, param.srcPos.y, param.srcPos.z);
  p.dstPos = make_cudaPos(param.dstPos.x * es, param.dstPos.y, param.dstPos.z);

  // "dimension of the transferred area in elements of unsigned char"
  p.extent = make_cudaExtent(param.extent.x * es, param.extent.y, param.extent.z);

  // we mark our srcPtr as `const void*` since we will not modify data through it, but the cuda pitchedPtr is just
  // `void*`
  p.srcPtr = param.srcPtr;
  p.dstPtr = param.dstPtr;

  p.kind = cudaMemcpyDeviceToDevice;
  LOG_SPEW("srcPtr.pitch " << p.srcPtr.pitch);
  LOG_SPEW("srcPtr.ptr " << p.srcPtr.ptr);
  LOG_SPEW("srcPos  [" << p.srcPos.x << "," << p.srcPos.y << "," << p.srcPos.z << "]");
  LOG_SPEW("dstPtr.pitch " << p.dstPtr.pitch);
  LOG_SPEW("dstPtr.ptr " << p.dstPtr.ptr);
  LOG_SPEW("dstPos  [" << p.dstPos.x << "," << p.dstPos.y << "," << p.dstPos.z << "]");
  LOG_SPEW("extent [dhw] = [" << p.extent.depth << "," << p.extent.height << "," << p.extent.width << "]");
  CUDA_RUNTIME(cudaMemcpy3DAsync(&p, stream));
}

void Translate::kernel(const Param &p, const int device, cudaStream_t stream) {
  const dim3 dimBlock = Dim3::make_block_dim(p.extent, 512 /*threads per block*/);
  const dim3 dimGrid = (p.extent + Dim3(dimBlock) - 1) / (Dim3(dimBlock));
  CUDA_RUNTIME(cudaSetDevice(device));
  LOG_SPEW("translate dev=" << device << " grid=" << dimGrid << " block=" << dimBlock);
  translate<<<dimGrid, dimBlock, 0, stream>>>(p.dstPtr, p.dstPos, p.srcPtr, p.srcPos, p.extent, p.elemSize);
}