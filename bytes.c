#include "bytes.h"

Slice * bytes_alloc(size_t capacity)
{
	char * memory = (char *) malloc(capacity + sizeof(BufferInfo));
	if (!memory) return NULL;

	Slice * slice = (Slice *) malloc(sizeof(Slice));
	if (!slice)
	{
		free(memory);
		return NULL;
	}

	slice->start = memory;
	slice->end = memory + capacity;

	return slice;
}

void bytes_free(Slice * slice)
{
	if (slice)
	{
		free(INFO(slice)->memory);
	}
}
