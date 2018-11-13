module Lib
    ( someFunc
    ) where

someFunc :: IO ()
someFunc = putStrLn "someFunc"

addThree :: Int -> Int -> Int -> Int
addThree x y z = x + y + z