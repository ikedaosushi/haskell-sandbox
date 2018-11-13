module Main where 
  import System.Environment
  import Text.ParserCombinators.Parsec hiding (spaces)
  import Control.Monad
  import Control.Monad

  data LispVal = Atom String
    | List [LispVal]
    | DottedList [LispVal] LispVal
    | Number Integer
    | String String
    | Bool Bool
  
  data LispError = NumArgs Integer [LispVal]
                 | TypeMismatch String LispVal
                 | Parser ParseError
                 | BadSpecialFrom String LispVal
                 | NotFunction String String 
                 | UnboundVar String String
                 | Default String 

  symbol :: Parser Char
  symbol = oneOf "!#$%&|*+-/:<=>?@^_~"

  spaces :: Parser ()
  spaces = skipMany1 space

  parseExpr :: Parser LispVal
  parseExpr = parseAtom 
          <|> parseString
          <|> parseNumber
          <|> parseQuoted
          <|> do char '('
                 x <- try parseList <|> parseDottedList
                 char ')'
                 return x

  parseString :: Parser LispVal
  parseString = do char '"'
                   x <- many (noneOf "\"")
                   char '"'
                   return $ String x
  
  parseAtom :: Parser LispVal
  parseAtom = do first <- letter <|> symbol
                 rest <- many (letter <|> digit <|> symbol)
                 let atom = first:rest
                 return $ case atom of 
                   "\t" -> Bool True
                   "#f" -> Bool False
                   _    -> Atom atom

  parseNumber :: Parser LispVal
  parseNumber = liftM (Number . read) $ many1 digit

  parseList :: Parser LispVal
  parseList = liftM List $ sepBy parseExpr spaces

  parseDottedList :: Parser LispVal
  parseDottedList = do
    head <- endBy parseExpr spaces
    tail <- char '.' >> spaces >> parseExpr
    return $ DottedList head tail

  parseQuoted :: Parser LispVal
  parseQuoted = do
    char '\''
    x <- parseExpr
    return $ List [Atom "quote", x]

  unwordsList :: [LispVal] -> String
  unwordsList = unwords . map showVal

  showVal :: LispVal -> String 
  showVal (String contents) = "\"" ++ contents ++ "\""
  showVal (Atom name) = name
  showVal (Number contents) = show contents
  showVal (Bool True) = "#t"
  showVal (Bool False) = "#t"
  showVal (List contents) = "(" ++ unwordsList contents ++ ")"
  showVal (DottedList head tail) = "(" ++ unwordsList head ++ " . " ++ showVal tail ++ ")"

  instance Show LispVal where show = showVal

  readExpr :: String -> LispVal 
  readExpr input = case parse parseExpr "lisp" input of
    Left err -> String $ "No match: " ++ show err
    Right val -> val
  
  eval :: LispVal -> LispVal
  eval val@(String _) = val
  eval val@(Number _) = val
  eval val@(Bool _) = val
  eval (List [Atom "quote", val]) = val
  eval (List (Atom func : args)) = apply func $ map eval args
  
  primitives :: [(String, [LispVal] -> LispVal)]
  primitives = [("+", numericBinop (+)),
                ("-", numericBinop (-)),
                ("*", numericBinop (*)),
                ("/", numericBinop div),
                ("mod", numericBinop mod),
                ("quotient", numericBinop quot),
                ("remainder", numericBinop rem)]
  
  apply :: String -> [LispVal] -> LispVal
  apply func args = maybe (Bool False) ($ args) $ lookup func primitives

  numericBinop :: (Integer -> Integer -> Integer) -> [LispVal] -> LispVal
  numericBinop op params = Number $ foldl1 op $ map unpackNum params

  unpackNum :: LispVal -> Integer
  unpackNum (Number n) = n
  unpackNum (String n) = let parsed = reads n in
                          if null parsed
                          then 0
                          else fst $ parsed !! 0
  unpackNum (List [n]) = unpackNum n
  unpackNum _ = 0

  main :: IO ()
  main = getArgs >>= print . eval . readExpr . head
