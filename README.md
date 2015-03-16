# idris-bytes

A FFI-based implementation of byte buffers for Idris.

* This is a cons-based structure (designed to grow to the left)
  and copying is avoided wherever possible --
  conses and prepends will not copy the RHS argument unless necessary.
  Instead, data is destructively written into pre-allocated spare space.

* Reading is designed to be very fast and straightforward.
  Mutation requires accessing the bookkeeping structure and possibly reallocation.

This will hopefully become the binary backend for
[idris-text](https://github.com/ziman/text).

## Installation

```bash
$ idris --build buffer.ipkg
$ idris --install buffer.ipkg
```
