module Data.Bytes

%flag C "-O0 -g3 -ggdb3"
%include C "bytes.h"
%link C "bytes.o"

%access public
%default total

Byte : Type
Byte = Int

abstract
record Bytes : Type where
  B : Ptr -> Bytes

-- TODO: check for NULL and report errors
private
alloc : Int -> IO Bytes
alloc capacity = B <$> foreign FFI_C "bytes_alloc" (Int -> IO Ptr) capacity

initialCapacity : Int
initialCapacity = 4096

abstract
empty : Bytes
empty = unsafePerformIO $ alloc initialCapacity

%freeze empty

abstract
cons : Byte -> Bytes -> Bytes
cons b (B ptr) = unsafePerformIO (
    B <$> foreign FFI_C "bytes_cons" (Int -> Ptr -> IO Ptr) b ptr
  )

%freeze cons

data ConsView : Bytes -> Type where
  Nil  : ConsView empty
  Cons : (b : Byte) -> (bs : Bytes) -> ConsView (cons b bs)

abstract
consView : (bs : Bytes) -> ConsView bs
consView (B ptr) = unsafePerformIO $ do
  empty <- foreign FFI_C "bytes_is_empty" (Ptr -> IO Int) ptr
  if empty == 1 then
    return . believe_me $ Data.Bytes.Nil
  else do
    hd <- foreign FFI_C "bytes_head" (Ptr -> IO Int) ptr
    tl <- foreign FFI_C "bytes_drop" (Int -> Ptr -> IO Ptr) 1 ptr
    return . believe_me $ Data.Bytes.Cons hd (B tl)

fromList : List Int -> Bytes
fromList []        = empty
fromList (x :: xs) = cons x $ fromList xs

toList : Bytes -> List Int
toList bs with (consView bs)
  toList  _          | Nil       = []
  toList (cons x xs) | Cons x xs = x :: toList (assert_smaller (cons x xs) xs)
