module Data.Bytes

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
abstract
allocate : Int -> Bytes
allocate capacity = unsafePerformIO (
    B <$> foreign FFI_C "bytes_alloc" (Int -> IO Ptr) capacity
  )

initialCapacity : Int
initialCapacity = 4088  -- 1 page minus bookkeeping

abstract
empty : Bytes
empty = allocate initialCapacity

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
  len <- foreign FFI_C "bytes_length" (Ptr -> IO Int) ptr
  if len == 0 then
    return . believe_me $ Data.Bytes.Nil
  else do
    hd <- foreign FFI_C "bytes_head" (Ptr -> IO Int) ptr
    tl <- foreign FFI_C "bytes_drop" (Int -> Ptr -> IO Ptr) 1 ptr
    return . believe_me $ Data.Bytes.Cons hd (B tl)

infixr 7 ++
abstract
(++) : Bytes -> Bytes -> Bytes
(++) (B xs) (B ys) = unsafePerformIO (
  B <$> foreign FFI_C "bytes_concat" (Ptr -> Ptr -> IO Ptr) xs ys
)

drop : Int -> Bytes -> Bytes
drop n (B ptr) = unsafePerformIO (
    B <$> foreign FFI_C "bytes_drop" (Int -> Ptr -> IO Ptr) n ptr
  )

take : Int -> Bytes -> Bytes
take n (B ptr) = unsafePerformIO (
    B <$> foreign FFI_C "bytes_take" (Int -> Ptr -> IO Ptr) n ptr
  )

fromList : List Int -> Bytes
fromList []        = empty
fromList (x :: xs) = cons x $ fromList xs

toList : Bytes -> List Int
toList bs with (consView bs)
  toList  _          | Nil       = []
  toList (cons x xs) | Cons x xs = x :: toList (assert_smaller (cons x xs) xs)
