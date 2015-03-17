#include "bytes.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef int bool_t;

/// Information about an allocated chunk, which is typically
/// referenced by multiple slices pointing into it.
typedef struct Buffer {
	// TODO: comment this
	uint8_t * dirt_l;
	uint8_t * dirt_r;

	/// Pointer to the first invalid byte after the buffer.
	uint8_t * end;

	/// The allocated chunk of memory.
	uint8_t start[];
} Buffer;

/// A slice of an underlying buffer.
typedef struct Slice {

	/// The first valid byte.
	uint8_t * start;

	/// The first byte past the end.
	uint8_t * end;

	/// Bookkeeping for the underlying allocated memory.
	Buffer * buffer;
} Slice;

/// Check if there's enough space to grow by nbytes to the left.
static inline bool_t enough_space_l(const Slice * const slice, const size_t nbytes)
{
	return (slice->start - slice->buffer->start) >= nbytes;
}

/// Check if there's enough space to grow by nbytes to the right.
static inline bool_t enough_space_r(const Slice * const slice, const size_t nbytes)
{
	return (slice->buffer->end - slice->end) >= nbytes;
}

Slice * bytes_alloc(size_t capacity, GrowthDirection alignment)
{
	Buffer * buffer = (Buffer *) malloc(sizeof(Buffer) + capacity);
	if (!buffer) return NULL;

	buffer->end = buffer->start + capacity;

	Slice * slice = (Slice *) malloc(sizeof(Slice));
	if (!slice)
	{
		free(buffer);
		return NULL;
	}

	switch (alignment)
	{
		case CONS:
			slice->start = slice->end = buffer->end;
			break;
		
		case SNOC:
		default:
			slice->start = slice->end = buffer->start;
			break;
	}

	buffer->dirt_l = slice->start;
	buffer->dirt_r = slice->end;

	return slice;
}

/**
 * Copy a slice, expanding its capacity capacity_factor-times.
 *
 *   capacity_factor = 1  --  simple copy
 *   capacity_factor = 2  --  double the capacity
 *
 * Please don't use capacity_factor = 0.
 */
static Slice * bytes_copy(Slice * slice, size_t capacity_factor, GrowthDirection dir)
{
	const size_t old_capacity = slice->buffer->end - slice->buffer->start;

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

	*result->start = (uint8_t) (byte & 0xFF);

	return result;
}

size_t bytes_length(Slice * slice)
{
	return slice->end - slice->start;
}

unsigned bytes_head(Slice * slice)
{
	return slice->start[0];
}

Slice * bytes_take(size_t nbytes, Slice * slice)
{
	Slice * result = bytes_alloc(nbytes);

	result->start = result->end - nbytes;
	memcpy(result->start, slice->start, nbytes);

	return result;
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
