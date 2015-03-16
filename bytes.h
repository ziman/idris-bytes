#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

// All functions return NULL on error.

typedef struct Slice Slice;

/// Allocate an empty slice with the given capacity.
/// May allocate slightly more to align internal structures.
Slice * bytes_alloc(size_t capacity);

Slice * bytes_cons(int byte, Slice * slice);

// O(1).
size_t bytes_length(Slice * slice);

// Does not perform any checks.
int bytes_head(Slice * slice);

// Does not perform any checks.
Slice * bytes_drop(size_t nbytes, Slice * slice);

// Will grow the right slice if possible.
Slice * bytes_concat(Slice * left, Slice * right);

#endif
