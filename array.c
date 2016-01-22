#include "array.h"
#include <string.h>

CData array_alloc(int size)
{
    return cdata_allocate((size_t) size, free);
}

uint8_t array_peek(int ofs, CData array)
{
    return ((uint8_t *) array->data)[ofs];
}

void array_poke(int ofs, uint8_t byte, CData array)
{
    ((uint8_t *) array->data)[ofs] = byte;
}

void array_copy(CData src, int src_ofs, CData dst, int dst_ofs, int count)
{
    // memmove rather than memcpy in case the areas overlap
    memmove(dst->data + dst_ofs, src->data + src_ofs, count);
}

void array_fill(int ofs, int count, uint8_t byte, CData array)
{
    memset(array->data + ofs, byte, count);
}

int array_compare(CData l, int lofs, CData r, int rofs, int count)
{
    return memcmp(l->data + lofs, r->data + rofs, count);
}
