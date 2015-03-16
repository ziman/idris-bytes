#include "bytes.h"

#include <stdlib.h>

struct Slice * bytes_alloc(size_t capacity)
{
	char * memory = (char *) malloc(capacity + sizeof(struct BufferInfo));
	if (!memory) return NULL;

	struct Slice * slice = (struct Slice *) malloc(sizeof(struct Slice));
	if (!slice)
	{
		free(memory);
		return NULL;
	}

	slice->start = memory;
	slice->end = memory + capacity;

	return slice;
}

void bytes_free(struct Slice * slice)
{
	if (slice)
	{
		free(INFO(slice)->memory);
	}
}
