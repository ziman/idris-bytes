module Main

import Data.Bytes as B

multi : Nat -> Bytes -> Bytes
multi  Z    bs = bs
multi (S n) bs = multi n bs ++ bs

main : IO ()
main = do
    putStrLn "Hello world!"
    print . B.unpack $ xs ++ ys
    print . B.unpack $ multi 10 xs
    print $ (xs ++ ys) == B.pack [1,2,3,254,255,0,1]
    print $ B.pack [64, 65, 66, 67, 68, 69]
  where
    xs : Bytes
    xs = pack [1, 2, 3]

    ys : Bytes
    ys = pack [254, 255, 256, 257]
