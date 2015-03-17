#ifndef BYTES_H
#define BYTES_H

#include <stddef.h>

// All functions return NULL on error.

typedef enum GrowthDirection {
	/// Start on the right, expecting to grow to the left.
	CONS = 0,

	/// Start on the left, expecting to grow to the right.
	SNOC = 1,
	
	/// Start in the middle.
	BOTH = 2
} GrowthDirection;

/// A slice is a view into an allocated buffer.
typedef struct Slice Slice;

/**
 * Allocate an empty slice with the given capacity.
 *
 * @param alignment Initial alignment of an slice in a buffer.
 * 	Note that a buffer can *always* grow both ways, it's
 * 	just wasteful to start it in the middle and then ever
 * 	grow only to one side.
 */
Slice * bytes_alloc(size_t capacity, GrowthDirection alignment);

Slice * bytes_cons(unsigned byte, Slice * slice);
Slice * bytes_snoc(Slice * slice, unsigned byte);

// O(1).
size_t bytes_length(Slice * slice);

// Does not perform any checks.
unsigned bytes_head(Slice * slice);
unsigned bytes_last(Slice * slice);

// Does not perform any checks.
Slice * bytes_take(size_t nbytes, Slice * slice);

// Does not perform any checks.
Slice * bytes_drop(size_t nbytes, Slice * slice);

// Append the right argument to the left argument.
Slice * bytes_append(Slice * left, Slice * right);

// Prepend the left argument to the right argument.
Slice * bytes_prepend(Slice * left, Slice * right);

#endif
