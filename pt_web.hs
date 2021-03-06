{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Network.Wreq
import Control.Lens
import Data.Aeson (Array, FromJSON, ToJSON, decode)
import Data.Text
import GHC.Generics
import Data.Maybe
import qualified Data.ByteString as S
import qualified Data.ByteString.Char8 as C
import qualified GHC.List as L
import qualified Control.Monad as M
import Data.DateTime
import System.Environment

pt_token = getEnv "PT_TOKEN"
pt_id = getEnv "PT_PROJECT_IDS"

pt_url = "https://www.pivotaltracker.com/services/v5/projects"
stories_url id = pt_url ++ "/" ++ id ++ "/iterations?offset=" 

pt_start_date = do 
    d <- getEnv "PT_START_DATE"
    return $ get_time $ pack d
 
pt_release_name = getEnv "PT_RELEASE_NAME"

main = do

    r_ids <- pt_id

    let ids' = split (==',') $ pack r_ids
    let ids = L.map unpack ids'

    mapM_ print_burndown ids

print_burndown id = do

    putStrLn $ "Project: " ++ id

    rn <- pt_release_name
    sd <- pt_start_date

    (t,b) <- get_burndown id sd rn 

    putStrLn $ "Total: " ++ show t
    mapM_ (\(x,y) -> 
        putStrLn $ show x ++ "\t" ++ show y) b

get_burndown id start_date release_name = do

    its <- get_all_iterations id

    let finish_d = find_finish_date release_name its
        f_its = release_iterations its start_date finish_d 

    return $ (iterations_total f_its, done_iterations f_its)

data Story = Story {
    name :: Text,
    story_type :: Text,
    current_state :: Text,
    estimate :: Maybe Int
} deriving (Eq, Show, Generic)

instance FromJSON Story

data Iteration = Iteration {
    start :: Text,
    finish :: Text,
    stories :: [Story]
} deriving (Eq, Show, Generic)

instance FromJSON Iteration

get_raw id offset = do

    tk <- pt_token

    let opts = defaults & header "X-TrackerToken" .~ [C.pack tk]
    getWith opts $ stories_url id ++ (show offset)

get_iterations s = 
    let d = s ^. responseBody
    in decode d :: Maybe [Iteration]

get_all :: [Char] -> Int -> [[Iteration]] -> IO [[Iteration]]
get_all id offset its = do

    s <- get_raw id offset 
    let i = fromJust $ get_iterations s 

    putStrLn $ show offset

    if i == []
      then return its 
      else get_all id (offset + 10) (i:its)

get_project :: [Char] -> IO [[Iteration]]
get_project id = get_all id 0 []

get_all_iterations id = do 

    its <- get_project id 

    let s = L.reverse its
    return $ M.join s 

get_time t = 
    fromJust $ parseDateTime "%Y-%m-%dT%H:%M:%SZ" $ unpack t

stories_total sts = 
    L.foldl (\acc s -> acc + (fromMaybe 0 $ estimate s)) 0 sts

stories_done sts = 
    L.foldl (\acc s -> 
        if (unpack $ current_state s) == "accepted" 
        then acc + (fromMaybe 0 $ estimate s)
        else acc) 0 sts

iterations_total its =
    L.foldl (\acc i -> acc + (stories_total $ stories i)) 0 its

release_iterations its start_t finish_t =
    L.filter (\i -> 
        ((get_time $ start i) >= start_t) && 
        ((get_time $ finish i) <= finish_t)) its

find_release release_n sts = 
    L.filter (\s -> 
        (story_type s == "release") && 
        ((unpack $ name s)== release_n)) sts

find_finish_date release_n its = 
    get_time $ finish $ L.head $ L.filter (\i -> 
        (L.length $ find_release release_n $ stories i) /= 0) its 

done_iterations its = 
    L.map (\i -> 
        ((finish i),(stories_done (stories i)))) its


