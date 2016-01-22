#pragma once

#include <stdint.h>
#include <stddef.h>

#include "idris_rts.h"

CData array_alloc(int size);
uint8_t array_peek(int ix, CData array);
void array_poke(int ix, uint8_t byte, CData array);
void array_copy(CData src, int src_ix, CData dst, int dst_ix, int count);
