module Main

import Data.ByteArray as BA
import Data.Bytes as B

%flag C "-O0 -ggdb -g3"

infixl 3 =<<
(=<<) : (a -> IO b) -> IO a -> IO b
f =<< x = x >>= f

multi : Nat -> Bytes -> Bytes
multi  Z    bs = bs
multi (S n) bs = multi n bs ++ bs

testBytes : IO ()
testBytes = do
    putStrLn "Hello world!"
    printLn . B.unpack $ xs ++ ys
    printLn . B.unpack $ multi 10 xs
    printLn $ (xs ++ ys) == B.pack [1,2,3,254,255,0,1]
    printLn $ B.pack [64, 65, 66, 67, 68, 69]
    printLn $ spanLength (== 128) (pack [128,128,128,0])
  where
    xs : Bytes
    xs = pack [1, 2, 3]

    ys : Bytes
    ys = pack [254, 255, 256, 257]

testByteArray : IO ()
testByteArray = do
    xs <- allocate 1024
    poke 64 42 xs
    printLn =<< peek 64 xs
    printLn =<< peek 84 xs
    copy (xs, 60) (xs, 80) 10
    printLn =<< peek 84 xs
    return ()

main : IO ()
main = do
    testByteArray
    testBytes
