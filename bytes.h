#ifndef BYTES_H
#define BYTES_H

struct BufferInfo {
	char * memory;
	size_t capacity;
};

struct Slice {
	char * start;
	char * end;
};

#define INFO(bytes) ((BufferInfo *) ((bytes)->end))

Slice * bytes_alloc(size_t capacity);
void bytes_free(Slice * slice);

#endif
