#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

struct BufferInfo {
	char * memory;
	size_t capacity;
};

struct Slice {
	char * start;
	char * end;
};

#define INFO(bytes) ((struct BufferInfo *) ((bytes)->end))

struct Slice * bytes_alloc(size_t capacity);
void bytes_free(struct Slice * slice);

#endif
