#include "bytes.h"

#include <stdlib.h>
#include <string.h>

typedef int bool_t;

/// Desired alignment of the BufferInfo structure.
#define INFO_ALIGNMENT sizeof(char *)

/// Information about an allocated chunk, which is typically
/// referenced by multiple slices pointing into it.
struct BufferInfo {

	/// The start of the allocated chunk of memory.
	char * memory;

	/** TODO: this should be synchronised if we go concurrent
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
	 * so that other slices know to copy the whole buffer on update.
	 */
	char * dirt;
};

/// A slice of an underlying buffer.
struct Slice {

	/// The first useful byte.
	char * start;

	/// The first byte past the end.
	char * end;
};

/// Get the buffer info.
#define INFO(slice) ((struct BufferInfo *) ((slice)->end))

/// Check if there's enough space to grow by nbytes.
inline bool_t enough_space(const struct Slice * const slice, const int bytes)
{
	return INFO(slice)->memory + bytes <= slice->start;
}

struct Slice * bytes_alloc(size_t capacity)
{
	// Make sure BufferInfo will be aligned
	if (capacity % INFO_ALIGNMENT != 0)
	{
		capacity += INFO_ALIGNMENT - (capacity % INFO_ALIGNMENT);
	}

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

/**
 * Copy a slice, expanding its capacity capacity_factor-times.
 *
 * capacity_factor = 1  --  simple copy
 * capacity_factor = 2  --  double the capacity
 *
 * Please don't use capacity_factor = 0.
 */
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

/// Prepend nbytes undefined bytes, reallocating the slice if needed.
/// This function prepares the space, you overwrite the newly added bytes.
struct Slice * bytes_bump(size_t nbytes, struct Slice * slice)
{
	struct BufferInfo * info = INFO(slice);

	while (!enough_space(slice, nbytes))
	{
		// not enough space -- grow the buffer
		slice = bytes_copy(slice, 2);
		if (!slice) return NULL;
	}

	if (info->dirt != slice->start)
	{
		// enough space but some other slice has already
		// grown into the available capacity
		slice = bytes_copy(slice, 1);
		if (!slice) return NULL;
	}

	// now we have
	// - enough available capacity
	// - not taken by any other slice
	// (and we know that start == dirt)
	//
	// => we can grow the slice

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
	return (int) slice->start[0];
}

struct Slice * bytes_drop(size_t nbytes, struct Slice * slice)
{
	struct Slice * new_slice = (struct Slice *) malloc(sizeof(struct Slice));
	if (!new_slice) return NULL;

	new_slice->start = slice->start + nbytes;
	new_slice->end   = slice->end;
	// note that the BufferInfo (esp. dirt) remains unchanged
	
	return new_slice;
}
