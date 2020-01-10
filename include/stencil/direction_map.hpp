#pragma once

#include <array>

/*! store a T associated with each direction vector
 */
template <typename T> class DirectionMap {

private:
  std::array<std::array<std::array<T, 3>, 3>, 3> data_;

public:
  typedef int index_type;

  bool operator==(const DirectionMap &rhs) const noexcept {
    return data_ == rhs.data_;
  }

  T &at(index_type x, index_type y, index_type z) noexcept {
    assert(x >= 0 && x <= 2);
    assert(x >= 0 && x <= 2);
    assert(x >= 0 && x <= 2);
    return data_[z][y][x];
  }

  T &at_dir(index_type x, index_type y, index_type z) noexcept {
    assert(x >= -1 && x <= 1);
    assert(x >= -1 && x <= 1);
    assert(x >= -1 && x <= 1);
    return data_[z + 1][y + 1][x + 1];
  }

  const T &at_dir(index_type x, index_type y, index_type z) const noexcept {
    return at_dir(x, y, z);
  }
};
