#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

/**
 * All functions return NULL on error.
 * All intervals are [half open).
 * Everything is copy-on-second-write. (First write mutates, if safe.)
 */

/// A slice is a view into an allocated buffer.
typedef struct Slice Slice;

/// Allocate an empty slice with the given capacity.
Slice * bytes_alloc(size_t capacity);

Slice * bytes_snoc(Slice * slice, unsigned byte);

// O(1).
size_t bytes_length(Slice * slice);

/// Generic O(1) indexing. Does not perform any checks.
unsigned bytes_at(Slice * slice, size_t index);
unsigned bytes_last(Slice * slice);

/// Get a subslice corresponding to the half-open interval [start, end).
/// Does not perform any checks.
Slice * bytes_slice(Slice * slice, size_t start, size_t end);

// Convenience wrappers.
Slice * bytes_take_prefix(size_t nbytes, Slice * slice);
Slice * bytes_drop_prefix(size_t nbytes, Slice * slice);
Slice * bytes_take_suffix(size_t nbytes, Slice * slice);
Slice * bytes_drop_suffix(size_t nbytes, Slice * slice);

// Append the right argument to the left argument.
// Will not copy the left argument unless necessary.
Slice * bytes_append(Slice * left, Slice * right);

#endif
