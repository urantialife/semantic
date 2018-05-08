{-# LANGUAGE ConstraintKinds, GeneralizedNewtypeDeriving, TypeFamilies #-}
module Data.Abstract.Cache where

import Control.Abstract.Evaluator
import Data.Abstract.Configuration
import Data.Abstract.Heap
import Data.Map.Monoidal as Monoidal
import Data.Semilattice.Lower
import Prologue

-- | A map of 'Configuration's to 'Set's of resulting values & 'Heap's.
newtype Cache term location cell value = Cache { unCache :: Monoidal.Map (Configuration term location cell value) (Set (ValueRef value, Heap location cell value)) }
  deriving (Eq, Lower, Monoid, Ord, Reducer (Configuration term location cell value, (ValueRef value, Heap location cell value)), Show, Semigroup)

type Cacheable term location cell value = (Ord (cell value), Ord location, Ord term, Ord value)

-- | Look up the resulting value & 'Heap' for a given 'Configuration'.
cacheLookup :: Cacheable term location cell value => Configuration term location cell value -> Cache term location cell value -> Maybe (Set (ValueRef value, Heap location cell value))
cacheLookup key = Monoidal.lookup key . unCache

-- | Set the resulting value & 'Heap' for a given 'Configuration', overwriting any previous entry.
cacheSet :: Cacheable term location cell value => Configuration term location cell value -> Set (ValueRef value, Heap location cell value) -> Cache term location cell value -> Cache term location cell value
cacheSet key value = Cache . Monoidal.insert key value . unCache

-- | Insert the resulting value & 'Heap' for a given 'Configuration', appending onto any previous entry.
cacheInsert :: Cacheable term location cell value => Configuration term location cell value -> (ValueRef value, Heap location cell value) -> Cache term location cell value -> Cache term location cell value
cacheInsert = curry cons
