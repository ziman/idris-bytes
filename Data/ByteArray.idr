module Data.ByteArray

%include C "array.h"
%link C "array.o"

%access public
%default total

namespace Byte
  Byte : Type
  Byte = Bits8

  toInt : Byte -> Int
  toInt = prim__zextB8_Int

  fromInt : Int -> Byte
  fromInt = prim__truncInt_B8

record ByteArray where
  constructor BA
  ptr : CData
  size : Int

abstract
allocate : Int -> IO ByteArray
allocate sz = do
  ptr <- foreign FFI_C "array_alloc" (Int -> IO CData) sz
  return $ BA ptr sz

abstract
peek : Int -> ByteArray -> IO Byte
peek ix (BA ptr sz)
  = if (ix < 0 || ix >= sz)
      then return 0
      else foreign FFI_C "array_peek" (Int -> CData -> IO Byte) ix ptr

abstract
poke : Int -> Byte -> ByteArray -> IO ()
poke ix b (BA ptr sz)
  = if (ix < 0 || ix >= sz)
      then return ()
      else foreign FFI_C "array_poke" (Int -> Byte -> CData -> IO ()) ix b ptr

abstract
copy : (ByteArray, Int) -> (ByteArray, Int) -> Int -> IO ()
copy (BA srcPtr srcSz, srcIx) (BA dstPtr dstSz, dstIx) count
  = if (srcIx < 0 || dstIx < 0 || (srcIx+count) >= srcSz || (dstIx+count) >= dstSz)
      then return ()
      else foreign FFI_C "array_copy" (CData -> Int -> CData -> Int -> Int -> IO ()) srcPtr srcIx dstPtr dstIx count
