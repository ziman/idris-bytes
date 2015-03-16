# idris-bytes

A FFI-based implementation of byte buffers for Idris.

* Reading is designed to be very fast and straightforward.
  Mutation requires accessing the bookkeeping structure and possibly reallocation.

* Copying is avoided wherever possible. Repeated conses are O(1) amortized.
  Appends will not copy the right argument unless necessary.

This will hopefully become the binary backend for
[https://github.com/ziman/text](idris-text).

## Installation

```bash
$ idris --build buffer.ipkg
$ idris --install buffer.ipkg
```
