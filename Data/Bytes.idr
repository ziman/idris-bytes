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

initialCapacity : Int
initialCapacity = 16

-- TODO: check for NULL and report errors

abstract
allocate : Int -> Bytes
allocate capacity = unsafePerformIO (
    B <$> foreign FFI_C "bytes_alloc" (Int -> IO Ptr) capacity
  )

abstract
length : Bytes -> Int
length (B ptr) = unsafePerformIO $
  foreign FFI_C "bytes_length" (Ptr -> IO Int) ptr

abstract
empty : Bytes
empty = allocate initialCapacity

%freeze empty

abstract
snoc : Bytes -> Byte -> Bytes
snoc (B ptr) b = unsafePerformIO (
    B <$> foreign FFI_C "bytes_snoc" (Ptr -> Int -> IO Ptr) ptr b
  )

%freeze cons

infixl 7 |>
(|>) : Bytes -> Byte -> Bytes
(|>) = snoc

namespace SnocView
  data SnocView : Type where
    Nil : SnocView
    Snoc : (bs : Bytes) -> (b : Byte) -> SnocView

  abstract
  snocView : Bytes -> SnocView
  snocView (B ptr) = unsafePerformIO $ do
    len <- foreign FFI_C "bytes_length" (Ptr -> IO Int) ptr
    if len == 0 then
      return $ SnocView.Nil
    else do
      init <- foreign FFI_C "bytes_drop_suffix" (Int -> Ptr -> IO Ptr) 1 ptr
      last <- foreign FFI_C "bytes_last" (Ptr -> IO Int) ptr
      return $ SnocView.Snoc (B init) last

namespace ConsView
  data ConsView : Type where
    Nil : ConsView
    Cons : (b : Byte) -> (bs : Bytes) -> ConsView

  abstract
  consView : Bytes -> ConsView
  consView (B ptr) = unsafePerformIO $ do
    len <- foreign FFI_C "bytes_length" (Ptr -> IO Int) ptr
    if len == 0 then
      return $ ConsView.Nil
    else do
      hd <- foreign FFI_C "bytes_head" (Ptr -> IO Int) ptr
      tl <- foreign FFI_C "bytes_drop_prefix" (Int -> Ptr -> IO Ptr) 1 ptr
      return $ ConsView.Cons hd (B tl)

infixr 7 ++
abstract
(++) : Bytes -> Bytes -> Bytes
(++) (B xs) (B ys) = unsafePerformIO (
  B <$> foreign FFI_C "bytes_append" (Ptr -> Ptr -> IO Ptr) xs ys
)

dropPrefix : Int -> Bytes -> Bytes
dropPrefix n (B ptr) = unsafePerformIO (
      B <$> foreign FFI_C "bytes_drop_prefix" (Int -> Ptr -> IO Ptr) (min n len) ptr
    )
  where
    len = length (B ptr)

takePrefix : Int -> Bytes -> Bytes
takePrefix n (B ptr) = unsafePerformIO (
      B <$> foreign FFI_C "bytes_take_prefix" (Int -> Ptr -> IO Ptr) (min n len) ptr
    )
  where
    len = length (B ptr)

fromList' : List Int -> Bytes
fromList' []        = empty
fromList' (x :: xs) = snoc (fromList' xs) x

fromList : List Int -> Bytes
fromList = fromList' . reverse

toList' : Bytes -> List Int
toList' bs with (snocView bs)
  | Nil       = []
  | Snoc xs x = x :: toList' (assert_smaller bs xs)

toList : Bytes -> List Int
toList = reverse . toList'

slice : Int -> Int -> Bytes -> Bytes
slice start end (B ptr) = unsafePerformIO (
      B <$> foreign FFI_C "bytes_slice" (Ptr -> Int -> Int -> IO Ptr) ptr s' e'
    )
  where
    n : Int
    n = length (B ptr)
    s : Int
    s = (start `min` n) `max` 0
    e : Int
    e = (end   `min` n) `max` 0
    s' : Int
    s' = min s e
    e' : Int
    e' = max s e

-- folds with early exit
data Result : Type -> Type where
  Stop : (result : a) -> Result a
  Cont : (acc : a) -> Result a

iterateR : (Byte -> a -> Result a) -> a -> Bytes -> a
iterateR f acc bs with (snocView bs)
  | Nil       = acc
  | Snoc ys y with (f y acc)
    | Stop result = result
    | Cont acc'   = iterateR f acc' (assert_smaller bs ys)

iterateL : (a -> Byte -> Result a) -> a -> Bytes -> a
iterateL f acc bs with (snocView bs)
  | Nil       = acc
  | Snoc ys y with (f acc y)
    | Stop result = result
    | Cont acc'   = iterateL f acc' (assert_smaller bs ys)

spanLength : (Byte -> Bool) -> Bytes -> Int
spanLength p = iterateL step 0
  where
    step : Int -> Byte -> Result Int
    step n b with (p b)
      | True  = Cont (n + 1)
      | False = Stop  n

-- todo:
--
-- spanLength
-- span, break
-- foldr, foldl
-- various instances, Eq, Ord, Show, Monoid
-- migrate to (Bits 8)
-- rename fromList/toList to pack/unpack
--
-- Bidirectional growth? (dirt_l, dirt_r)
