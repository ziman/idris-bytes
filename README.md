# idris-bytes

A FFI-based implementation of byte buffers for Idris.

* This is a snoc-based structure (designed to grow to the right).

* Reading is unrestricted -- we provide `consView`, as well as `snocView`,
  subslicing and arbitrary indexing, all in O(1).

* Copying is avoided wherever possible (copy-on-second-write) --
  snocs and appends will not copy the LHS argument unless necessary.
  Instead, data is destructively written into pre-allocated spare space,
  as long as it is safe.

* Built on top of `Data.ByteArray`, `IO`-based mutable byte arrays.

This is the binary backend for [idris-text](https://github.com/ziman/text).

## Installation

```bash
$ idris --build bytes.ipkg
$ idris --install bytes.ipkg
```
