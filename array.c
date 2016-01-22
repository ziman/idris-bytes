#include "array.h"
#include <string.h>

CData array_alloc(int size)
{
    return cdata_allocate((size_t) size, free);
}

uint8_t array_peek(int ix, CData array)
{
    return ((uint8_t *) array->data)[ix];
}

void array_poke(int ix, uint8_t byte, CData array)
{
    ((uint8_t *) array->data)[ix] = byte;
}

void array_copy(CData src, int src_ix, CData dst, int dst_ix, int count)
{
    // memmove rather than memcpy in case the areas overlap
    memmove(dst->data + dst_ix, src->data + src_ix, count);
}
