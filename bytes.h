#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

// All functions return NULL on error.

struct Slice;

struct Slice * bytes_alloc(size_t capacity);
struct Slice * bytes_cons(int byte, struct Slice * slice);
int            bytes_is_empty(struct Slice * slice);
int            bytes_head(struct Slice * slice);
struct Slice * bytes_drop(size_t nbytes, struct Slice * slice);

#endif
