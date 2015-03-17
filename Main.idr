module Main

import Data.Bytes

multi : Nat -> Bytes -> Bytes
multi  Z    bs = bs
multi (S n) bs = multi n bs ++ bs

main : IO ()
main = do
    putStrLn "Hello world!"
    print . Bytes.toList $ xs ++ ys
    print . Bytes.toList $ multi 10 xs
  where
    xs : Bytes
    xs = fromList [1, 2, 3]

    ys : Bytes
    ys = fromList [254, 255, 256, 257]
