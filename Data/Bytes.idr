module Data.Bytes

import Data.ByteArray as BA

%include C "bytes.h"
%link C "bytes.o"

%access public
%default total

-- Structure of the allocated ByteArray
--   [used_size][.....data.....]
-- used_size is an int and it takes up BA.bytesPerInt bytes
-- at the beginning of the array

abstract
record Bytes where
  constructor B
  arr : ByteArray
  ofs : Int
  end : Int  -- first offset not included in the array

minimalCapacity : Int
minimalCapacity = 16

private
allocate : Int -> IO Bytes
allocate capacity = do
  arr <- BA.allocate (BA.bytesPerInt + capacity)
  BA.pokeInt 0 bytesPerInt arr
  BA.fill bytesPerInt capacity 0 arr  -- zero the array
  return $ B arr bytesPerInt bytesPerInt

abstract
length : Bytes -> Int
length (B arr ofs end) = end - ofs

abstract
empty : Bytes
empty = unsafePerformIO $ allocate minimalCapacity

%freeze empty

-- factor=1 ~ copy
-- factor=2 ~ grow
private
grow : Int -> Bytes -> IO Bytes
grow factor (B arr ofs end) = do
  maxUsed <- BA.peekInt 0 arr
  let bytesUsed = end - ofs
  let bytesAvailable =
        if maxUsed > end
          then bytesUsed
          else BA.size arr - ofs
  B arr' ofs' end' <- allocate $ (factor*bytesAvailable) `max` minimalCapacity
  BA.copy (arr, ofs) (arr', ofs') bytesUsed
  return $ B arr' ofs' (ofs' + bytesUsed)

%assert_total
abstract
snoc : Bytes -> Byte -> Bytes
snoc bs@(B arr ofs end) byte
    = if end >= BA.size arr
        then unsafePerformIO $ do  -- need more space
          grown <- grow 2 bs
          return $ snoc grown byte
        else unsafePerformIO $ do
          maxUsed <- BA.peekInt 0 arr
          if maxUsed > end
            then do  -- someone already took the headroom, need copying
              copy <- grow 2 bs
              return $ snoc copy byte
            else do  -- can mutate
              BA.pokeInt 0 (end+1) arr
              BA.poke (end+1) byte arr
              return $ B arr ofs (end+1)

infixl 7 |>
(|>) : Bytes -> Byte -> Bytes
(|>) = snoc

namespace SnocView
  data SnocView : Type where
    Nil : SnocView
    Snoc : (bs : Bytes) -> (b : Byte) -> SnocView

  abstract
  snocView : Bytes -> SnocView
  snocView (B arr ofs end) =
    if end == ofs
      then SnocView.Nil
      else unsafePerformIO $ do
        last <- BA.peek (end-1) arr
        return $ SnocView.Snoc (B arr ofs (end-1)) last

namespace ConsView
  data ConsView : Type where
    Nil : ConsView
    Cons : (b : Byte) -> (bs : Bytes) -> ConsView

  abstract
  consView : Bytes -> ConsView
  consView (B arr ofs end) =
    if end == ofs
      then ConsView.Nil
      else unsafePerformIO $ do
        first <- BA.peek ofs arr
        return $ ConsView.Cons first (B arr (ofs+1) end)

infixr 7 ++
%assert_total
abstract
(++) : Bytes -> Bytes -> Bytes
(++) bsL@(B arrL ofsL endL) bsR@(B arrR ofsR endR)
  = let countR = endR - ofsR in
      if endL + countR > BA.size arrL
        then unsafePerformIO $ do  -- need more space
          grown <- grow 2 bsL
          return $ grown ++ bsR
        else unsafePerformIO $ do
          maxUsedL <- BA.peekInt 0 arrL
          if maxUsedL > endL
            then do  -- headroom taken
              copyL <- grow 2 bsL
              return $ copyL ++ bsR
            else do  -- can mutate
              BA.pokeInt 0 (endL + countR) arrL
              BA.copy (arrR, ofsR) (arrL, endL) countR
              return $ B arrL ofsL (endL + countR)

{-
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
iterateL f acc bs with (consView bs)
  | Nil       = acc
  | Cons y ys with (f acc y)
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

toString : Bytes -> String
toString = foldr (strCons . chr . toInt) ""

fromString : String -> Bytes
fromString = foldl (\bs, c => bs |> fromInt (ord c)) empty . unpack

instance Show Bytes where
  show = ("b" ++) . show . toString

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
-}
