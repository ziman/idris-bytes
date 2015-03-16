module Data.Bytes

%link C "bytes.o"

%access public

abstract
record Bytes : Type where
  MkBytes : Ptr -> Bytes

private
alloc : Int -> IO Bytes
alloc capacity = MkBytes <$> foreign FFI_C "bytes_alloc" (Int -> IO Ptr) capacity

private
free : Bytes -> IO ()
free (MkBytes ptr) = foreign FFI_C "bytes_free" (Ptr -> IO ()) ptr
