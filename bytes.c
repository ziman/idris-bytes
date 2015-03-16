#include "bytes.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef int bool_t;

/// Desired alignment of the BufferInfo structure.
#define INFO_ALIGNMENT sizeof(uint8_t *)

/// Information about an allocated chunk, which is typically
/// referenced by multiple slices pointing into it.
struct BufferInfo {

	/// The start of the allocated chunk of memory.
	uint8_t * memory;

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
	uint8_t * dirt;
};

/// A slice of an underlying buffer.
struct Slice {

	/// The first useful byte.
	uint8_t * start;

	/// The first byte past the end.
	uint8_t * end;
};

/// Get the buffer info.
#define INFO(slice) ((struct BufferInfo *) ((slice)->end))

/// Check if there's enough space to grow by nbytes.
inline bool_t enough_space(const Slice * const slice, const int bytes)
{
	return INFO(slice)->memory + bytes <= slice->start;
}

Slice * bytes_alloc(size_t capacity)
{
	// Make sure BufferInfo will be aligned
	if (capacity % INFO_ALIGNMENT != 0)
	{
		capacity += INFO_ALIGNMENT - (capacity % INFO_ALIGNMENT);
	}

	uint8_t * memory = (uint8_t *) malloc(capacity + sizeof(struct BufferInfo));
	if (!memory) return NULL;

	Slice * slice = (Slice *) malloc(sizeof(Slice));
	if (!slice)
	{
		free(memory);
		return NULL;
	}

	uint8_t * const end = memory + capacity;
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
Slice * bytes_copy(Slice * slice, size_t capacity_factor)
{
	const size_t old_capacity = slice->end - INFO(slice)->memory;

	// allocate a new slice
	Slice * result = bytes_alloc(capacity_factor * old_capacity);
	if (!result) return NULL;

	// copy the data
	const size_t length = slice->end - slice->start;
	result->start = result->end - length;
	memcpy(result->start, slice->start, length);

	// fix the info
	INFO(result)->dirt = result->start;

	return result;
}

/// Prepend nbytes undefined bytes, reallocating the slice if needed.
/// This function prepares the space, you overwrite the newly added bytes.
Slice * bytes_bump(size_t nbytes, Slice * slice)
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

Slice * bytes_cons(unsigned byte, Slice * slice)
{
	Slice * const result = bytes_bump(1, slice);
	if (!result) return NULL;

	*result->start = (uint8_t) ((unsigned) byte & 0xFF);

	return result;
}

size_t bytes_length(Slice * slice)
{
	return slice->end - slice->start;
}

unsigned bytes_head(Slice * slice)
{
	return (int) slice->start[0];
}

Slice * bytes_drop(size_t nbytes, Slice * slice)
{
	Slice * result = (Slice *) malloc(sizeof(Slice));
	if (!result) return NULL;

	result->start = slice->start + nbytes;
	result->end   = slice->end;
	// note that the BufferInfo (esp. dirt) remains unchanged
	
	return result;
}

Slice * bytes_concat(Slice * left, Slice * right)
{
	size_t nbytes = bytes_length(left);
	Slice * result = bytes_bump(nbytes, right);
	memcpy(result->start, left->start, nbytes);

	return result;
}
