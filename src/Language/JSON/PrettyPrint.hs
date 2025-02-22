module Language.JSON.PrettyPrint
  ( defaultBeautyOpts
  , defaultJSONPipeline
  , printingJSON
  , beautifyingJSON
  , minimizingJSON
  ) where

import Prologue

import           Control.Effect
import           Control.Effect.Error
import           Streaming
import qualified Streaming.Prelude as Streaming

import Data.Reprinting.Errors
import Data.Reprinting.Scope
import Data.Reprinting.Splice
import Data.Reprinting.Token

-- | Default printing pipeline for JSON.
defaultJSONPipeline :: (Member (Error TranslationError) sig, Carrier sig m)
                    => Stream (Of Fragment) m a
                    -> Stream (Of Splice) m a
defaultJSONPipeline
  = beautifyingJSON defaultBeautyOpts
  . printingJSON

-- | Print JSON syntax.
printingJSON :: Monad m
             => Stream (Of Fragment) m a
             -> Stream (Of Fragment) m a
printingJSON = Streaming.map step where
  step s@(Defer el cs) =
    let ins = New el cs
    in case (el, listToMaybe cs) of
      (Truth True, _)    -> ins "true"
      (Truth False, _)   -> ins "false"
      (Nullity, _)       -> ins "null"

      (Open,  Just List) -> ins "["
      (Close, Just List) -> ins "]"
      (Open,  Just Hash) -> ins "{"
      (Close, Just Hash) -> ins "}"

      (Sep, Just List)   -> ins ","
      (Sep, Just Pair)   -> ins ":"
      (Sep, Just Hash)   -> ins ","

      _                  -> s
  step x = x

-- TODO: Fill out and implement configurable options like indentation count,
-- tabs vs. spaces, etc.
data JSONBeautyOpts = JSONBeautyOpts { jsonIndent :: Int, jsonUseTabs :: Bool }
  deriving (Eq, Show)

defaultBeautyOpts :: JSONBeautyOpts
defaultBeautyOpts = JSONBeautyOpts 2 False

-- | Produce JSON with configurable whitespace and layout.
beautifyingJSON :: (Member (Error TranslationError) sig, Carrier sig m)
                => JSONBeautyOpts
                -> Stream (Of Fragment) m a
                -> Stream (Of Splice) m a
beautifyingJSON _ s = Streaming.for s step where
  step (Defer el cs)   = effect (throwError (NoTranslation el cs))
  step (Verbatim txt)  = emit txt
  step (New el cs txt) = case (el, cs) of
    (Open,  Hash:_)    -> emit txt *> layout HardWrap *> indent 2 (hashDepth cs)
    (Close, Hash:rest) -> layout HardWrap *> indent 2 (hashDepth rest) *> emit txt
    (Sep,   List:_)    -> emit txt *> space
    (Sep,   Pair:_)    -> emit txt *> space
    (Sep,   Hash:_)    -> emit txt *> layout HardWrap *> indent 2 (hashDepth cs)
    _                  -> emit txt

-- | Produce whitespace minimal JSON.
minimizingJSON :: (Member (Error TranslationError) sig, Carrier sig m)
               => Stream (Of Fragment) m a
               -> Stream (Of Splice) m a
minimizingJSON s = Streaming.for s step where
  step (Defer el cs)  = effect (throwError (NoTranslation el cs))
  step (Verbatim txt) = emit txt
  step (New _ _ txt)  = emit txt

hashDepth :: [Scope] -> Int
hashDepth = length . filter (== Hash)
