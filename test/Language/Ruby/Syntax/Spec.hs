module Language.Ruby.Syntax.Spec where

import Data.Functor.Union
import qualified Data.Syntax.Comment as Comment
import Language.Ruby.Syntax
import Prologue
import Test.Hspec

spec :: Spec
spec = do
  describe "stepAssignment" $ do
    it "matches nodes" $
      stepAssignment comment [ast Comment "hello" []] `shouldBe` Just ([], wrapU (Comment.Comment "hello") :: Program Syntax ())

    it "attempts multiple alternatives" $
      stepAssignment (if' <|> comment) [ast Comment "hello" []] `shouldBe` Just ([], wrapU (Comment.Comment "hello") :: Program Syntax ())

    it "matches in sequence" $
      stepAssignment ((,) <$> comment <*> comment) [ast Comment "hello" [], ast Comment "world" []] `shouldBe` Just ([], (wrapU (Comment.Comment "hello"), wrapU (Comment.Comment "world")) :: (Program Syntax (), Program Syntax ()))

    it "matches repetitions" $
      stepAssignment (many comment) [ast Comment "colourless" [], ast Comment "green" [], ast Comment "ideas" [], ast Comment "sleep" [], ast Comment "furiously" []] `shouldBe` Just ([], [wrapU (Comment.Comment "colourless"), wrapU (Comment.Comment "green"), wrapU (Comment.Comment "ideas"), wrapU (Comment.Comment "sleep"), wrapU (Comment.Comment "furiously")] :: [Program Syntax ()])

    it "matches one-or-more repetitions against one or more input nodes" $
      stepAssignment (some comment) [ast Comment "hello" []] `shouldBe` Just ([], [wrapU (Comment.Comment "hello")] :: [Program Syntax ()])

ast :: Grammar -> ByteString -> [AST Grammar] -> AST Grammar
ast g s c = Rose (Node g s) c
