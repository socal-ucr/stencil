# stencil

A prototype MPI/CUDA stencil halo exchange library

## Quick Start

Install MPI and CUDA, then

```
git clone git@github.com:cwpearson/stencil.git
cd stencil
mkdir build
cd build
cmake ..
make
mpirun -n 4 src/main
```

## Tests

Install MPI and CUDA, then

```
make && make test
```

Some tests are tagged:

MPI tests only
```
test/test_all "[mpi]"
```

CUDA tests only
```
test/test_all "[cuda]"
```

## Design Goals
  * v1 (prototype)
    * joint stencils over multiple data types (Astaroth)
    * user-defined stencil kernels (Astaroth)
    * edge communication (Astaroth)
    * corner communication (Astaroth)
    * CPU stencil (HPCG)
  * future
    * pitched arrays (performance)
    * optimized communication (performance)
      * https://blogs.fau.de/wittmann/2013/02/mpi-node-local-rank-determination/
      * https://stackoverflow.com/questions/9022496/how-to-determine-mpi-rank-process-number-local-to-a-socket-node
    * Stop decomposition early
    * support larger halos for fewer, larger messages
