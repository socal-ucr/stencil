#include "catch2/catch.hpp"

#include <cstring> // std::memcpy

#include "stencil/copy.cuh"
#include "stencil/cuda_runtime.hpp"
#include "stencil/dim3.hpp"
#include "stencil/stencil.hpp"

__device__ int pack_xyz(int x, int y, int z) {
  int ret = 0;
  ret |= x & 0x3FF;
  ret |= (y & 0x3FF) << 10;
  ret |= (z & 0x3FF) << 20;
  return ret;
}

int unpack_x(int a) { return a & 0x3FF; }

int unpack_y(int a) { return (a >> 10) & 0x3FF; }

int unpack_z(int a) { return (a >> 20) & 0x3FF; }

template <typename T>
__global__ void
init_kernel(T *dst,            //<! [out] pointer to beginning of dst allocation
            const Dim3 origin, //<! [in]
            const Dim3 rawSz   //<! [in] 3D size of the dst and src allocations
) {

  constexpr size_t radius = 1;
  const Dim3 domSz = rawSz - Dim3(2 * radius, 2 * radius, 2 * radius);

  const size_t gdz = gridDim.z;
  const size_t biz = blockIdx.z;
  const size_t bdz = blockDim.z;
  const size_t tiz = threadIdx.z;

  const size_t gdy = gridDim.y;
  const size_t biy = blockIdx.y;
  const size_t bdy = blockDim.y;
  const size_t tiy = threadIdx.y;

  const size_t gdx = gridDim.x;
  const size_t bix = blockIdx.x;
  const size_t bdx = blockDim.x;
  const size_t tix = threadIdx.x;

#define _at(arr, _x, _y, _z) arr[_z * rawSz.y * rawSz.x + _y * rawSz.x + _x]

  // initialize the compute domain and set halos to zero
  for (size_t z = biz * bdz + tiz; z < rawSz.z; z += gdz * bdz) {
    for (size_t y = biy * bdy + tiy; y < rawSz.y; y += gdy * bdy) {
      for (size_t x = bix * bdx + tix; x < rawSz.x; x += gdx * bdx) {

        if (z >= radius && x >= radius && y >= radius && z < rawSz.z - radius &&
            y < rawSz.y - radius && x < rawSz.x - radius) {
          _at(dst, x, y, z) =
              pack_xyz(origin.x + x, origin.y + y, origin.z + z);
        } else {
          _at(dst, x, y, z) = 0.0;
        }
      }
    }
  }

#undef _at
}

TEST_CASE("exchange") {

  int rank;
  int size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  size_t radius = 1;
  typedef float Q1;

  INFO("ctor");
  DistributedDomain dd(10, 10, 10);
  dd.set_radius(radius);
  auto dh1 = dd.add_data<Q1>();
  dd.set_methods(MethodFlags::CudaMpi);

  INFO("realize");
  dd.realize();

  INFO("device sync");
  for (auto &d : dd.domains()) {
    CUDA_RUNTIME(cudaSetDevice(d.gpu()));
    CUDA_RUNTIME(cudaDeviceSynchronize());
  }

  INFO("barrier");
  MPI_Barrier(MPI_COMM_WORLD);

  INFO("init");
  dim3 dimGrid(10, 10, 10);
  dim3 dimBlock(8, 8, 8);
  for (size_t di = 0; di < dd.domains().size(); ++di) {
    auto &d = dd.domains()[di];
    REQUIRE(d.get_curr(dh1) != nullptr);
    std::cerr << d.raw_size() << "\n";
    CUDA_RUNTIME(cudaSetDevice(d.gpu()));
    init_kernel<<<dimGrid, dimBlock>>>(d.get_curr(dh1), dd.origins()[di],
                                       d.raw_size());
    CUDA_RUNTIME(cudaDeviceSynchronize());
  }

  MPI_Barrier(MPI_COMM_WORLD);

  // test initialization
  INFO("test init interior");
  for (size_t di = 0; di < dd.domains().size(); ++di) {
    auto &d = dd.domains()[di];
    const Dim3 ext = d.halo_extent(Dim3(0, 0, 0));

    for (size_t qi = 0; qi < d.num_data(); ++qi) {
      std::cerr << "here\n";
      auto vec = d.interior_to_host(qi);
      std::cerr << "here2\n";

      // make sure we can access data as a Q1
      std::vector<Q1> interior(ext.flatten());
      REQUIRE(vec.size() == interior.size() * sizeof(Q1));
      std::memcpy(interior.data(), vec.data(), vec.size());

      // int64_t z = 0;
      // for (int64_t y = 0; y < ext.y; ++y) {
      //   for (int64_t x = 0; x < ext.x; ++x) {
      //     Q1 val = interior[z * (ext.y * ext.x) + y * (ext.x) + x];
      //     if (0 == rank)
      //       std::cout << val << " ";
      //   }
      //   if (0 == rank)
      //     std::cout << "\n";
      // }

      for (int64_t z = 0; z < ext.z; ++z) {
        for (int64_t y = 0; y < ext.y; ++y) {
          for (int64_t x = 0; x < ext.x; ++x) {
            Q1 val = interior[z * (ext.y * ext.x) + y * (ext.x) + x];
            REQUIRE(unpack_x(val) == x + radius);
            REQUIRE(unpack_y(val) == y + radius);
            REQUIRE(unpack_z(val) == z + radius);
          }
        }
      }
    }
  }

  MPI_Barrier(MPI_COMM_WORLD);

  INFO("exchange");

  dd.exchange();
  std::cerr << "here2\n";
  CUDA_RUNTIME(cudaDeviceSynchronize());

  INFO("interior should be unchanged");
  for (auto &d : dd.domains()) {
    const Dim3 ext = d.halo_extent(Dim3(0, 0, 0));

    for (size_t qi = 0; qi < d.num_data(); ++qi) {
      auto vec = d.interior_to_host(qi);

      // make sure we can access data as a Q1
      std::vector<Q1> interior(ext.flatten());
      REQUIRE(vec.size() == interior.size() * sizeof(Q1));
      std::memcpy(interior.data(), vec.data(), vec.size());

      for (int64_t z = 0; z < ext.z; ++z) {
        for (int64_t y = 0; y < ext.y; ++y) {
          for (int64_t x = 0; x < ext.x; ++x) {
            Q1 val = interior[z * (ext.y * ext.x) + y * (ext.x) + x];
            REQUIRE(unpack_x(val) == x + radius);
            REQUIRE(unpack_y(val) == y + radius);
            REQUIRE(unpack_z(val) == z + radius);
          }
        }
      }
    }
  }

  INFO("check halo regions");

  /*
  for (auto &sd : dd.domains()) {

    std::vector<Q1> quantity = sd.quantity_to_host(0);

    for (int dz = -1; dz <= 1; ++dz) {
      for (int dy = -1; dy <= 1; ++dy) {
        for (int dz = -1; dz <= 1; ++dz) {
          const Dim3 dir(dx, dy, dz);
          const Dim3 pos = sd.halo_pos(dir);
          const Dim3 ext = sd.halo_extent(dir);
          const Dim3 sz = sd.raw_size();

          for (int zi = pos.z; zi < pos.z + ext.z; ++zi) {
            for (int yi = pos.z; yi < pos.z + ext.z; ++yi) {
              for (int xi = pos.z; xi < pos.z + ext.z; ++xi) {
                Q1 val = quantity[zi * (sz.y * sz.x) + yi * (sz.x) + xi];
                REQUIRE(unpack_x(val) == x + radius);
                REQUIRE(unpack_y(val) == y + radius);
                REQUIRE(unpack_z(val) == z + radius);
              }
            }
          }
        }
      }
    }
  }
  */
}
