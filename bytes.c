#include "bytes.h"

#include <stdlib.h>
#include <string.h>

typedef int bool_t;

// TODO: alignment of BufferInfo!

struct BufferInfo {
	/// The start of the allocated chunk of memory.
	char * memory;

	/** TODO: this should be synchronised
	 *
	 * This is a hack that allows us to cons bytes to slices
	 * by mutating the underlying buffer instead of copying,
	 * as long as there is only one "line of extension".
	 *
	 * This field denotes the start of the earliest slice
	 * that uses this buffer as its underlying storage.
	 *
	 * Hence, if you are extending a slice and
	 *   dirt == slice->start
	 * you can choose to extend your slice and update dirt
	 * so that other slices have to copy the whole buffer.
	 */
	char * dirt;
};

struct Slice {
	char * start;
	char * end;
};

#define INFO(bytes) ((struct BufferInfo *) ((bytes)->end))

inline bool_t has_space(const struct Slice * const slice, const int bytes)
{
	return INFO(slice)->memory + bytes <= slice->start;
}


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

	char * const end = memory + capacity;
	slice->start = end;
	slice->end = end;

	struct BufferInfo * info = INFO(slice);
	info->memory = memory;
	info->dirt = end;

	return slice;
}

struct Slice * bytes_copy(struct Slice * slice, size_t capacity_factor)
{
	const size_t old_capacity = slice->end - INFO(slice)->memory;

	// allocate a new slice
	struct Slice * new_slice = bytes_alloc(capacity_factor * old_capacity);
	if (!new_slice) return NULL;

	// copy the data
	const size_t length = slice->end - slice->start;
	new_slice->start = new_slice->end - length;
	memcpy(new_slice->start, slice->start, length);

	// fix the info
	INFO(new_slice)->dirt = new_slice->start;

	return new_slice;
}

void bytes_free(struct Slice * slice)
{
	if (!slice) return;
	free(INFO(slice)->memory);
}

struct Slice * bytes_bump(size_t nbytes, struct Slice * slice)
{
	struct BufferInfo * info = INFO(slice);

	while (!has_space(slice, nbytes))
	{
		// not enough space -- grow the buffer
		slice = bytes_copy(slice, 2);
		if (!slice) return NULL;
	}

	if (info->dirt != slice->start)
	{
		// enough space but someone has already
		// grown into the empty space
		slice = bytes_copy(slice, 1);
		if (!slice) return NULL;
	}

	// now the slice is completely ours
	// and we know that (start == dirt).

	slice->start -= nbytes;
	INFO(slice)->dirt = slice->start;

	return slice;
}

struct Slice * bytes_cons(int byte, struct Slice * slice)
{
	struct Slice * const new_slice = bytes_bump(1, slice);
	if (!new_slice) return NULL;

	*new_slice->start = (char) (byte & 0xFF);

	return new_slice;
}

int bytes_is_empty(struct Slice * slice)
{
	return slice->start == slice->end;
}

int bytes_head(struct Slice * slice)
{
	return (int) *slice->start;
}

struct Slice * bytes_uncons(size_t nbytes, struct Slice * slice)
{
	struct Slice * new_slice = (struct Slice *) malloc(sizeof(struct Slice));
	if (!new_slice) return NULL;

	new_slice->start += nbytes;
	// note that the dirt remains where it is
	
	return new_slice;
}
