module Main

import Data.Bytes

main : IO ()
main = do
    putStrLn "Hello world!"
    print . Bytes.toList $ xs ++ ys
  where
    xs : Bytes
    xs = fromList [1, 2, 3]

    ys : Bytes
    ys = fromList [254, 255, 256, 257]
