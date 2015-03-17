#include "bytes.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef int bool_t;

/// Information about an allocated chunk, which is typically
/// referenced by multiple slices pointing into it.
typedef struct Buffer {

	/// First byte not included in any slice.
	uint8_t * free_space;

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

/// Check if there's enough space to grow by nbytes to the right.
static inline bool_t enough_space(const Slice * const slice, const size_t nbytes)
{
	return (slice->buffer->end - slice->end) >= nbytes;
}

static Buffer * new_buffer(size_t capacity)
{
	Buffer * buffer = (Buffer *) malloc(sizeof(Buffer) + capacity);
	if (!buffer) return NULL;

	buffer->end = buffer->start + capacity;
	buffer->free_space = buffer->start;

	return buffer;
}

static Slice * new_slice(Buffer * buffer, uint8_t * start, uint8_t * end)
{
	Slice * slice = (Slice *) malloc(sizeof(Slice));
	if (!slice) return NULL;

	slice->buffer = buffer;
	slice->start = start;
	slice->end = end;

	if (end > buffer->free_space)
		buffer->free_space = end;

	return slice;
}

Slice * bytes_alloc(size_t capacity)
{
	Buffer * buffer = new_buffer(capacity);
	if (!buffer) return NULL;

	Slice * slice = new_slice(buffer, buffer->start, buffer->start);
	if (!slice)
	{
		free(buffer);
		return NULL;
	}

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
static Slice * bytes_copy(Slice * slice, size_t capacity_factor)
{
	const size_t old_capacity = slice->buffer->end - slice->buffer->start;

	// allocate a new slice
	Slice * result = bytes_alloc(capacity_factor * old_capacity);
	if (!result) return NULL;

	// copy the data
	const size_t length = slice->end - slice->start;
	result->end = result->start + length;
	memcpy(result->start, slice->start, length);

	// update buffer info
	result->buffer->free_space = result->end;

	return result;
}

/// Append nbytes undefined bytes, reallocating the slice if needed.
/// This function prepares the space, you overwrite the newly added bytes.
Slice * bytes_bump(size_t nbytes, Slice * slice)
{
	while (!enough_space(slice, nbytes))
	{
		// not enough space -- grow the buffer
		slice = bytes_copy(slice, 2);
		if (!slice) return NULL;
	}

	if (slice->buffer->free_space > slice->end)
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

	slice->end += nbytes;
	slice->buffer->free_space = slice->end;

	return slice;
}

Slice * bytes_snoc(Slice * slice, unsigned byte)
{
	Slice * const result = bytes_bump(1, slice);
	if (!result) return NULL;

	result->end[-1] = (uint8_t) (byte & 0xFF);

	return result;
}

size_t bytes_length(Slice * slice)
{
	return slice->end - slice->start;
}

unsigned bytes_at(Slice * slice, size_t index)
{
	return (unsigned) slice->start[index];
}

unsigned bytes_last(Slice * slice)
{
	return (unsigned) slice->end[-1];
}

Slice * bytes_slice(Slice * slice, size_t start, size_t end)
{
	return new_slice(slice->buffer, slice->start + start, slice->start + end);
}

Slice * bytes_take_prefix(size_t nbytes, Slice * slice)
{
	return new_slice(slice->buffer, slice->start, slice->start + nbytes);
}

Slice * bytes_drop_prefix(size_t nbytes, Slice * slice)
{
	return new_slice(slice->buffer, slice->start + nbytes, slice->end);
}

Slice * bytes_take_suffix(size_t nbytes, Slice * slice)
{
	return new_slice(slice->buffer, slice->end - nbytes, slice->end);
}

Slice * bytes_drop_suffix(size_t nbytes, Slice * slice)
{
	return new_slice(slice->buffer, slice->start, slice->end - nbytes);
}

Slice * bytes_append(Slice * left, Slice * right)
{
	size_t llen = bytes_length(left);
	size_t rlen = bytes_length(right);

	Slice * result = bytes_bump(rlen, left);

	memcpy(result->start + llen, left->start, rlen);

	return result;
}
