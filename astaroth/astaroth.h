#pragma once

#include <cfloat>

#define AC_DOUBLE_PRECISION 1

// Library flags
#define STENCIL_ORDER (6)
#define NGHOST (STENCIL_ORDER / 2)

// a few things from astaroth.h
#define AcReal double
#define AcReal3 double3
#define AC_REAL_MAX (DBL_MAX)
#define AC_REAL_MIN (DBL_MIN)
#define AC_REAL_EPSILON (DBL_EPSILON)
typedef struct {
  AcReal3 row[3];
} AcMatrix;

// all defined in the code generator
// #define NUM_VTXBUF_HANDLES 8

#include "user_defines.h" // Autogenerated defines from the DSL

typedef enum { AC_SUCCESS = 0, AC_FAILURE = 1 } AcResult;

typedef enum { AC_BOUNDCOND_PERIODIC = 0, AC_BOUNDCOND_SYMMETRIC = 1, AC_BOUNDCOND_ANTISYMMETRIC = 2 } AcBoundcond;

#define AC_GEN_ID(X) X,
typedef enum {
  AC_FOR_RTYPES(AC_GEN_ID) //
  NUM_RTYPES
} ReductionType;

typedef enum {
  AC_FOR_USER_INT_PARAM_TYPES(AC_GEN_ID) //
  NUM_INT_PARAMS
} AcIntParam;

typedef enum {
  AC_FOR_USER_INT3_PARAM_TYPES(AC_GEN_ID) //
  NUM_INT3_PARAMS
} AcInt3Param;

typedef enum {
  AC_FOR_USER_REAL_PARAM_TYPES(AC_GEN_ID) //
  NUM_REAL_PARAMS
} AcRealParam;

typedef enum {
  AC_FOR_USER_REAL3_PARAM_TYPES(AC_GEN_ID) //
  NUM_REAL3_PARAMS
} AcReal3Param;

typedef enum {
  AC_FOR_SCALARARRAY_HANDLES(AC_GEN_ID) //
  NUM_SCALARARRAY_HANDLES
} ScalarArrayHandle;

typedef enum {
  AC_FOR_VTXBUF_HANDLES(AC_GEN_ID) //
  NUM_VTXBUF_HANDLES
} VertexBufferHandle;
#undef AC_GEN_ID

#define _UNUSED __attribute__((unused)) // Does not give a warning if unused
#define AC_GEN_STR(X) #X,
static const char *rtype_names[] _UNUSED = {AC_FOR_RTYPES(AC_GEN_STR) "-end-"};
static const char *intparam_names[] _UNUSED = {AC_FOR_USER_INT_PARAM_TYPES(AC_GEN_STR) "-end-"};
static const char *int3param_names[] _UNUSED = {AC_FOR_USER_INT3_PARAM_TYPES(AC_GEN_STR) "-end-"};
static const char *realparam_names[] _UNUSED = {AC_FOR_USER_REAL_PARAM_TYPES(AC_GEN_STR) "-end-"};
static const char *real3param_names[] _UNUSED = {AC_FOR_USER_REAL3_PARAM_TYPES(AC_GEN_STR) "-end-"};
static const char *scalararray_names[] _UNUSED = {AC_FOR_SCALARARRAY_HANDLES(AC_GEN_STR) "-end-"};
static const char *vtxbuf_names[] _UNUSED = {AC_FOR_VTXBUF_HANDLES(AC_GEN_STR) "-end-"};
#undef AC_GEN_STR
#undef _UNUSED

typedef struct {
  int int_params[NUM_INT_PARAMS];
  int3 int3_params[NUM_INT3_PARAMS];
  AcReal real_params[NUM_REAL_PARAMS];
  AcReal3 real3_params[NUM_REAL3_PARAMS];
} AcMeshInfo;

// Device
typedef struct device_s *Device; // Opaque pointer to device_s. Analogous to dispatchable handles
                                 // in Vulkan, f.ex. VkDevice

#define AC_MPI_ENABLED 1

AcResult acDeviceCreate(const int id, const AcMeshInfo device_config, Device *device);