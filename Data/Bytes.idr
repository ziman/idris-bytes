module Data.Bytes

%link C "bytes.o"

%access public
%default total

Byte : Type
Byte = Int

abstract
record Bytes : Type where
  MkBytes : Ptr -> Bytes

-- TODO: check for NULL and report errors
private
alloc : Int -> IO Bytes
alloc capacity = MkBytes <$> foreign FFI_C "bytes_alloc" (Int -> IO Ptr) capacity

private
free : Bytes -> IO ()
free (MkBytes ptr) = foreign FFI_C "bytes_free" (Ptr -> IO ()) ptr

initialCapacity : Int
initialCapacity = 4096

empty : Bytes
empty = unsafePerformIO $ alloc initialCapacity

cons : Byte -> Bytes -> Bytes
cons b (MkBytes ptr) = unsafePerformIO (
    MkBytes <$> foreign FFI_C "bytes_cons" (Int -> Ptr -> IO Ptr) b ptr
  )
