module Data.Bytes

%include C "bytes.h"
%link C "bytes.o"

%access public
%default total

namespace Byte
  Byte : Type
  Byte = Bits8

  toInt : Byte -> Int
  toInt = prim__zextB8_Int

  fromInt : Int -> Byte
  fromInt = prim__truncInt_B8

abstract
record Bytes : Type where
  B : Ptr -> Bytes

initialCapacity : Nat
initialCapacity = 16

-- TODO: check for NULL and report errors

abstract
allocate : Nat -> Bytes
allocate capacity = unsafePerformIO (
    B <$> foreign FFI_C "bytes_alloc" (Int -> IO Ptr) (cast capacity)
  )

private
length_Int : Bytes -> Int
length_Int (B ptr) = unsafePerformIO $
  foreign FFI_C "bytes_length" (Ptr -> IO Int) ptr

abstract
length : Bytes -> Nat
length = cast . length_Int

abstract
empty : Bytes
empty = allocate initialCapacity

%freeze empty

abstract
snoc : Bytes -> Byte -> Bytes
snoc (B ptr) b = unsafePerformIO (
    B <$> foreign FFI_C "bytes_snoc" (Ptr -> Byte -> IO Ptr) ptr b
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
      last <- foreign FFI_C "bytes_last" (Ptr -> IO Byte) ptr
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
      hd <- foreign FFI_C "bytes_head" (Ptr -> IO Byte) ptr
      tl <- foreign FFI_C "bytes_drop_prefix" (Int -> Ptr -> IO Ptr) 1 ptr
      return $ ConsView.Cons hd (B tl)

infixr 7 ++
abstract
(++) : Bytes -> Bytes -> Bytes
(++) (B xs) (B ys) = unsafePerformIO (
  B <$> foreign FFI_C "bytes_append" (Ptr -> Ptr -> IO Ptr) xs ys
)

dropPrefix : Nat -> Bytes -> Bytes
dropPrefix n (B ptr) = unsafePerformIO (
      B <$> foreign FFI_C "bytes_drop_prefix" (Int -> Ptr -> IO Ptr) (min (cast n) len) ptr
    )
  where
    len = length_Int (B ptr)

takePrefix : Nat -> Bytes -> Bytes
takePrefix n (B ptr) = unsafePerformIO (
      B <$> foreign FFI_C "bytes_take_prefix" (Int -> Ptr -> IO Ptr) (min (cast n) len) ptr
    )
  where
    len = length_Int (B ptr)

pack : List Byte -> Bytes
pack = fromList . reverse
  where
    fromList : List Byte -> Bytes
    fromList []        = empty
    fromList (x :: xs) = snoc (fromList xs) x

unpack : Bytes -> List Byte
unpack bs with (consView bs)
  | Nil       = []
  | Cons x xs = x :: unpack (assert_smaller bs xs)

slice : Nat -> Nat -> Bytes -> Bytes
slice start end (B ptr) = unsafePerformIO (
      B <$> foreign FFI_C "bytes_slice" (Ptr -> Int -> Int -> IO Ptr) ptr s' e'
    )
  where
    n : Int
    n = length_Int (B ptr)
    s : Int
    s = (cast start `min` n) `max` 0
    e : Int
    e = (cast end   `min` n) `max` 0
    s' : Int
    s' = min s e
    e' : Int
    e' = max s e

-- Folds with early exit.
-- If Bytes were a Functor, this would be equivalent
-- to a Traversable instance interpreted in the Either monad.
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

infixl 3 .:
(.:) : (a -> b) -> (c -> d -> a) -> (c -> d -> b)
(.:) g f x y = g (f x y)

foldr : (Byte -> a -> a) -> a -> Bytes -> a
foldr f = iterateR (Cont .: f)

foldl : (a -> Byte -> a) -> a -> Bytes -> a
foldl f = iterateL (Cont .: f)

spanLength : (Byte -> Bool) -> Bytes -> Nat
spanLength p = iterateL step Z
  where
    step : Nat -> Byte -> Result Nat
    step n b with (p b)
      | True  = Cont (S n)
      | False = Stop n

splitAt : Nat -> Bytes -> (Bytes, Bytes)
splitAt n bs = (takePrefix n bs, dropPrefix n bs)

span : (Byte -> Bool) -> Bytes -> (Bytes, Bytes)
span p bs = splitAt (spanLength p bs) bs

break : (Byte -> Bool) -> Bytes -> (Bytes, Bytes)
break p bs = span (not . p) bs

private
cmp : Bytes -> Bytes -> Int
cmp (B xs) (B ys) = unsafePerformIO $
  foreign FFI_C "bytes_compare" (Ptr -> Ptr -> IO Int) xs ys

instance Eq Bytes where
  xs == ys = (Bytes.cmp xs ys == 0)

instance Ord Bytes where
  compare xs ys =
      if x < 0
        then LT
        else if x > 0
          then GT
          else EQ
    where
      x : Int
      x = Bytes.cmp xs ys

instance Show Bytes where
  show = ("b" ++) . show . foldr (strCons . chr . toInt) ""

instance Semigroup Bytes where
  (<+>) = (++)

instance Monoid Bytes where
  neutral = empty

-- todo:
--
-- make indices Nats
-- Build a ByteString on top of Bytes?
-- migrate to (Bits 8)?
--
-- bidirectional growth?
