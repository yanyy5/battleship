-- File    : Proj2.hs
-- Author  : ---- ---- <------@student.unimelb.edu.au>
-- Purpose : Implements the two-player "BattleShip Guess Game" played on a 4x8
--           grid and providing feedback about the number of correct location
--           and 1 or 2 distance away to the correct location. 
--
-- ============================= Main Functions ===============================
-- toLocation :: String -> Maybe Location
--           Gives Just the Location named by the string, or Nothing if the 
--           string is not a valid location name.
--
-- fromLocation :: Location -> String
--           Gives back the two-character string version of the specified 
--           location; for any location loc, toLocation (fromLocation loc) 
--           should return Just loc.
--
-- feedback :: [Location] -> [Location] -> Score
--           Takes a target and a guess, respectively, and returns the 
--           appropriate feedback, as specified above.
--
-- initialGuess :: ([Location],GameState)
--           Takes no input arguments, and returns a pair of an initial guess 
--           and a game state.
--
-- nextGuess :: ([Location],GameState) -> Score -> ([Location],GameState)
--           Takes as input a pair of the previous guess and game state, and 
--           the feedback to this guess as a triple of the number of correct 
--           locations, the number of guesses exactly one square away from a 
--           ship, and the number exactly two squares away, and returns a pair 
--           of the next guess and new game state.
--
-- =============================== Background =================================
-- The game is somewhat akin to the game of Battleship™, but somewhat 
-- simplified. The game is played on a 4×8 grid, and involves one player, the 
-- searcher trying to find the locations of three battleships hidden by the 
-- other player, the hider. The searcher continues to guess until they find all 
-- the hidden ships. Unlike Battleship™, a guess consists of three different 
-- locations, and the game continues until the exact locations of the three 
-- hidden ships are guessed in a single guess. After each guess, the hider 
-- responds with three numbers:
--           1. the number of ships exactly located;
--           2. the number of guesses that were exactly one space away from a 
--              ship;
--           3. the number of guesses that were exactly two spaces away from a 
--              ship.
-- 
-- The game finishes once the searcher guesses all three ship locations in a 
-- single guess (in any order), such as in the last example above. The object 
-- of the game for the searcher is to find the target with the fewest possible 
-- guesses.
--
-- ============================================================================

module Proj2 (Location, toLocation, fromLocation, feedback,
              GameState, initialGuess, nextGuess) where

import Data.List

-- Data and type --------------------------------------------------------------

-- | Col: Represents the Columns of the 4x8 grid.
data Col = A|B|C|D|E|F|G|H
    deriving (Show,Eq,Ord,Enum,Read)

-- | Location: Represents grid locations in the game. The Col is defined above.
--   And the row is defined as Int type. It derives from Show, Eq and Ord.
data Location = Location Col Int
    deriving (Show,Eq,Ord)

-- | GameState: Represents list of remained possible guesses. Each of them 
--   consists of a list of 3 locations.
type GameState = [[Location]]

-- | Score: The three number responded from hider.
type Score = (Int, Int, Int)

-- Function -------------------------------------------------------------------

-- | toLocation
--   Params     : String
--   Return     : Location
--   Description: Return a Location when input a String type location. If the 
--   input String is invalid, it will return Nothing. The length of the input 
--   String should be 2. And the first element should be A-H. The second 
--   element should be 1-4.
toLocation :: String -> Maybe Location
toLocation str
    | length str == 2 && elem (head str) ['A'..'H'] 
      && elem (last str) ['1'..'4']
      = Just (Location (read [(head str)] :: Col) (read [(last str)] :: Int))
    | otherwise = Nothing

-- | fromLocation
--   Params     : Location
--   Return     : String
--   Description: Return a String when input a Location. We can assume that the 
--   input Location is valid.
fromLocation :: Location -> String
fromLocation (Location col row) = show col ++ show row

-- | feedback
--   Params     : [Location], [Location]
--   Return     : Score
--   Description: Given the target and guess location, return feedback score
--   of the guess accuracy in the form of Score type. The calculation is based
--   on the distance implemented below.
feedback :: [Location] -> [Location] -> Score
feedback [t1,t2,t3] [g1,g2,g3] = (space0,space1,space2)
    where 
    space0 = length (intersect [t1,t2,t3] [g1,g2,g3]) 
    space1 = length $ filter(==1) [d1,d2,d3]
    space2 = length $ filter(==2) [d1,d2,d3]
    d1 = minimum [(distance t1 g1),(distance t2 g1),(distance t3 g1)]
    d2 = minimum [(distance t1 g2),(distance t2 g2),(distance t3 g2)]
    d3 = minimum [(distance t1 g3),(distance t2 g3),(distance t3 g3)]

-- | distance
--   Params     : Location, Location
--   Return     : Int
--   Description: Given two locations, and calculate their distance defined in
--   the specs.
distance :: Location -> Location -> Int
distance (Location c1 r1) (Location c2 r2) = max colGap rowGap
    where 
    colGap = abs ((fromEnum c1) - (fromEnum c2))
    rowGap = abs (r1-r2)

-- | initialGuess
--   Return     : ([Location],GameState)
--   Description: Provides an initial guess and initializes the game state. To 
--   choose the best initial guess location, I make its cover area as large as
--   possible to gain more information from feedback. And the game state 
--   includes all(4096) the three combinations of grids.
initialGuess :: ([Location],GameState)
initialGuess = (firstGuess, gameState)
    where
    firstGuess = [Location A 4, Location D 1, Location H 2]
    allGuess = [Location col row | col <- [A,B,C,D,E,F,G,H], row <- [1..4]]
    gameState = [[loc1,loc2,loc3] | loc1 <- allGuess, loc2 <- allGuess, 
        loc3 <- allGuess, loc1<loc2, loc2<loc3]

-- | nextGuess
--   Params     : ([Location],GameState), Score
--   Return     : ([Location],GameState)
--   Description: Given the previous guess, game state and feedback score,
--   calculate the next guess and update the game state. In the game state,
--   only those having same feedback as previous guess will be retained. And
--   the index of next guess in the game state are calculated based on hint 6.
nextGuess :: ([Location],GameState) -> Score -> ([Location],GameState)
nextGuess (prevGuess,prevGameState) prevFeedback = (nextGuess,nextGameState)
    where
    newGameState = [target | target <- prevGameState, 
        feedback target prevGuess == prevFeedback]
    nextGameState = delete prevGuess newGameState
    nextGuess = nextGameState !! (bestIndex nextGameState)

-- | baseIndex
--   Params     : GameState
--   Return     : Int
--   Description: Based on hint 6 in the specs, find out the index of best 
--   guess in the game state. The guess with minimum expectation score are the
--   best. The list of feedback score and the calculation of expectation are
--   defined below.
bestIndex :: GameState -> Int
bestIndex gameState = index
    where
    expScores = [score | state <- gameState, 
        let newState = delete state gameState,
        let score = expScore $ allFeedback newState state]
    index = head (elemIndices (minimum expScores) expScores)

-- | allFeedback
--   Params     : GameState, [Location]
--   Return     : [Score]
--   Description: This is one of the helper function in bestIndex. To calculate
--   each possible expectation, first we need to generate a list of feedback
--   score. And use this list to calcutate expectation and find the minumum.
allFeedback :: GameState -> [Location] -> [Score]
allFeedback [] _ = []
allFeedback (state:states) loc  = (feedback loc state):(allFeedback states loc)

-- | expScore
--   Params     : [Score]
--   Return     : Float
--   Description: This is the implementation of hint 6. Given the list of 
--   remaining possible locations, calculate the expectation of the number of 
--   targets that will be left.
expScore :: [Score] -> Float
expScore scores = sum [ (num*num)/len | e <- groupedScores, 
    let num = fromIntegral (length e)]
    where 
    groupedScores = group $ sort scores
    len = fromIntegral (length scores)