module Main

import Data.Bytes

idBytes : Nat -> Bytes -> Bytes
idBytes  Z    bs = bs
idBytes (S n) bs = idBytes n bs 

main : IO ()
main = do
  putStrLn "Hello world!"
  print . Bytes.toList . idBytes 4 . Bytes.fromList $ [1, 2, 3, 4, 5]
