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
    print $ (xs ++ ys) == (fromList [1,2,3,254,255,0,1])
    print $ Bytes.fromList [64, 65, 66, 67, 68, 69]
  where
    xs : Bytes
    xs = fromList [1, 2, 3]

    ys : Bytes
    ys = fromList [254, 255, 256, 257]
