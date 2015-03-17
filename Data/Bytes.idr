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

data SnocView : Bytes -> Type where
  Nil  : SnocView empty
  Snoc : (bs : Bytes) -> (b : Byte) -> SnocView (bs |> b)

abstract
snocView : (bs : Bytes) -> SnocView bs
snocView (B ptr) = unsafePerformIO $ do
  len <- foreign FFI_C "bytes_length" (Ptr -> IO Int) ptr
  if len == 0 then
    return . believe_me $ Data.Bytes.Nil
  else do
    init <- foreign FFI_C "bytes_drop_suffix" (Int -> Ptr -> IO Ptr) 1 ptr
    last <- foreign FFI_C "bytes_last" (Ptr -> IO Int) ptr
    return . believe_me $ Data.Bytes.Snoc (B init) last

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
  toList'  _          | Nil       = []
  toList' (snoc xs x) | Snoc xs x = x :: toList' (assert_smaller (snoc xs x) xs)

toList : Bytes -> List Int
toList = reverse . toList'

-- todo:
--
-- lengthOfSpan
-- span, break
-- foldr, foldl
-- various instances, Eq, Ord, Show, Monoid
-- migrate to (Bits 8)
-- rename fromList/toList to pack/unpack
--
-- Bidirectional growth? (dirt_l, dirt_r)
