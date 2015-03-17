# idris-bytes

A FFI-based implementation of byte buffers for Idris.

* This is a snoc-based structure (designed to grow to the right).

* Copying is avoided wherever possible (copy-on-second-write) --
  snocs and appends will not copy the LHS argument unless necessary.
  Instead, data is destructively written into pre-allocated spare space,
  as long as it is safe.

* Reading is designed to be fast and straightforward.
  Mutation requires accessing the bookkeeping structure and possibly reallocation.

This will hopefully become the binary backend for
[idris-text](https://github.com/ziman/text).

## Installation

```bash
$ idris --build buffer.ipkg
$ idris --install buffer.ipkg
```
