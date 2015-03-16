#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

// All functions return NULL on error.

struct Slice;

/// Allocate an empty slice with the given capacity.
/// May allocate slightly more to align internal structures.
struct Slice * bytes_alloc(size_t capacity);

struct Slice * bytes_cons(int byte, struct Slice * slice);

int            bytes_is_empty(struct Slice * slice);

// Does not perform any checks.
int            bytes_head(struct Slice * slice);

// Does not perform any checks.
struct Slice * bytes_drop(size_t nbytes, struct Slice * slice);

#endif
