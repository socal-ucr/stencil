#pragma once

#include <cassert>
#include <cstdint>
#include <cstdlib>
#include <iostream>

#include "stencil/direction_map.hpp"

// #define SPEW(x) std::cerr << "SPEW[" << __FILE__ << ":" << __LINE__ << "] " <<  x << "\n";
#define SPEW(x)

class Radius {
private:
  DirectionMap<size_t> rads_;

public:
  size_t &dir(int x, int y, int z) { return rads_.at_dir(x, y, z); }
  const size_t &dir(int x, int y, int z) const { return rads_.at_dir(x, y, z); }

  const size_t &x(int d) const noexcept {
    assert(d >= -1);
    assert(d <= 1);
    SPEW("d=" << d);
    return dir(d, 0, 0);
  }
  const size_t &y(int d) const noexcept {
    assert(d >= -1);
    assert(d <= 1);
    return dir(0, d, 0);
  }
  const size_t &z(int d) const noexcept {
    assert(d >= -1);
    assert(d <= 1);
    return dir(0, 0, d);
  }

  bool operator==(const Radius &rhs) const noexcept {
    return rhs.rads_ == rads_;
  }

  void set_face(const size_t r) {
    rads_.at(0, 0, 1) = r;
    rads_.at(0, 0, 2) = r;
    rads_.at(0, 1, 0) = r;
    rads_.at(0, 2, 0) = r;
    rads_.at(1, 0, 0) = r;
    rads_.at(2, 0, 0) = r;
  }

  void set_edge(const size_t r) {
    rads_.at(0, 1, 1) = r;
    rads_.at(0, 1, 2) = r;
    rads_.at(0, 2, 1) = r;
    rads_.at(0, 2, 2) = r;
    rads_.at(1, 0, 1) = r;
    rads_.at(1, 0, 2) = r;
    rads_.at(2, 0, 1) = r;
    rads_.at(2, 0, 2) = r;
    rads_.at(1, 1, 0) = r;
    rads_.at(1, 2, 0) = r;
    rads_.at(2, 1, 0) = r;
    rads_.at(2, 2, 0) = r;
  }

  void set_corner(const size_t r) {
    rads_.at(1, 1, 1) = r;
    rads_.at(1, 1, 2) = r;
    rads_.at(1, 2, 1) = r;
    rads_.at(1, 2, 2) = r;
    rads_.at(2, 1, 1) = r;
    rads_.at(2, 1, 2) = r;
    rads_.at(2, 2, 1) = r;
    rads_.at(2, 2, 2) = r;
  }

  static Radius constant(const size_t r) {
    Radius result;
    for (int zi = 0; zi < 3; ++zi) {
      for (int yi = 0; yi < 3; ++yi) {
        for (int xi = 0; xi < 3; ++xi) {
          result.rads_.at(xi, yi, zi) = r;
        }
      }
    }
    return result;
  }

  /* \brief face-edge-corner radius
   */
  static Radius face_edge_corner(const size_t face, const size_t edge,
                                 const size_t corner) {
    Radius result;
    result.set_face(face);
    result.set_edge(edge);
    result.set_corner(corner);
    result.rads_.at_dir(0, 0, 0) = 0;
    return result;
  }
};

#undef SPEW