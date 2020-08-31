#pragma once

#if STENCIL_USE_MPI == 1
#include <mpi.h>
#endif

#include <vector>
#include <string>

namespace mpi {

inline int comm_rank(MPI_Comm comm) {
#if STENCIL_USE_MPI == 1
  int rank;
  MPI_Comm_rank(comm, &rank);
  return rank;
#else
  return 0;
#endif
}

inline int comm_size(MPI_Comm comm) {
#if STENCIL_USE_MPI == 1
  int size;
  MPI_Comm_size(comm, &size);
  return size;
#else
  return 1;
#endif
}

inline int world_rank() { return comm_rank(MPI_COMM_WORLD); }

inline int world_size() { return comm_size(MPI_COMM_WORLD); }

/* return a string of size() no more than MPI_MAX_PROCESSOR_NAME
*/
inline std::string processor_name() {
  char hostname[MPI_MAX_PROCESSOR_NAME] = {0};
  int nameLen;
  MPI_Get_processor_name(hostname, &nameLen);
  return std::string(hostname);
}



struct ColocatedInfo {
  MPI_Comm comm; // shared-memory communicator
  std::vector<int> ranks; // list of co-located ranks
};




} // namespace mpi