#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

struct Slice;

struct Slice * bytes_alloc(size_t capacity);
void           bytes_free(struct Slice * slice);

struct Slice * bytes_cons(int byte, struct Slice * slice);

#endif
