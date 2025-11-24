import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import asyncio
import aiohttp
from tqdm.asyncio import tqdm_asyncio
from tqdm import tqdm
import time
import sys
from asyncio import Lock

from helpers import write_json_list, parse_match_data
from helpers import LEAGUE_DIVISIONS, LEAGUE_TIERS, LEAGUE_TIERS_ELITE, LEAGUE_TIERS_LOW


ACCESS_POINT = "https://americas.api.riotgames.com"

# You can get an API Key from https://developer.riotgames.com/
api_key = input("API Key: ")
sys.stdout.write("\033[F")
sys.stdout.write("\033[K") 
print("API Key: ********")

RATE_LIMIT = 100
WINDOW = 120  # seconds
REQUEST_INTERVAL = WINDOW / RATE_LIMIT  # 1.2s (for 100 requests per 2 minutes)
MAX_CONCURRENT_REQUESTS = 5

concurrency_semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)
last_request_time = 0
request_lock = Lock()

#----------------------------------------------------------------------------------------------------

async def refresh_api_key(session: aiohttp.ClientSession):
    key = await asyncio.to_thread(input, "API Key needs to be refreshed. \n API KEY: ")
    global api_key
    api_key = key

async def rate_limited_wait():
    global last_request_time
    async with request_lock:
        now = time.monotonic()
        wait_time = last_request_time + REQUEST_INTERVAL - now
        if wait_time > 0:
            await asyncio.sleep(wait_time)
        last_request_time = time.monotonic()

async def limited_request(session, url, max_retries=5):
    async with concurrency_semaphore: 
        for attempt in range(max_retries):
            await rate_limited_wait()
            try:
                async with session.get(url) as resp:
                    if resp.status in (400, 401): # api key expired
                        print("[ERROR] API KEY EXPIRED")
                        sys.exit(1)
                        continue

                    if resp.status == 429: # rate limited
                        retry_after = int(resp.headers.get("Retry-After", 1))
                        print(f"Rate limited, retrying after {retry_after} seconds")
                        await asyncio.sleep(retry_after + 0.1)
                        continue
                    
                    resp.raise_for_status() # raise any other errors
                    return await resp.json() # return
                
            except aiohttp.ClientResponseError as e:
                if attempt == max_retries - 1:
                    raise
                await asyncio.sleep(0.5 * (2 ** attempt))
        raise Exception(f"Failed after {max_retries} retries: {url}")

#----------------------------------------------------------------------------------------------------
# request constructors

async def request_page(session, tier, division, page):
    na1_access_point = 'https://na1.api.riotgames.com'
    if tier in LEAGUE_TIERS_ELITE:
        url = f"{na1_access_point}/lol/league/v4/{tier.lower()}leagues/by-queue/RANKED_SOLO_5x5?api_key={api_key}"
        response = await limited_request(session, url)
        return response['entries']
    else:
        url = f"{na1_access_point}/lol/league/v4/entries/RANKED_SOLO_5x5/{tier}/{division}?page={page}&api_key={api_key}"
        return await limited_request(session, url)

async def request_matches_from_puuid(session, puuid, count = 100):
    url = f"{ACCESS_POINT}/lol/match/v5/matches/by-puuid/{puuid}/ids?start=0&count={count}&api_key={api_key}"
    return await limited_request(session, url)

async def request_data_from_match_id(session, match_id):
    url = f"{ACCESS_POINT}/lol/match/v5/matches/{match_id}?api_key={api_key}"
    return await limited_request(session, url)

async def request_timeline_from_match_id(session, match_id):
    url = f"{ACCESS_POINT}/lol/match/v5/matches/{match_id}/timeline?api_key={api_key}"
    return await limited_request(session, url)

#-------------------------------------------------------------------------------------
# getting players

async def get_players_by_division(session, tier, division, player_count):
    results = []
    page_number = 1
    while(len(results) < player_count):
        tqdm.write(f"[INFO] Fetching league page data no.{len(results)} for {tier} {division}")
        page_data = await request_page(session, tier, division, page_number)
        results.extend(page_data)
        page_number += 1
    return results[:player_count]

async def get_players_from_all_divisions(session, player_count):
    results = []
    for tier in LEAGUE_TIERS_LOW:
        for division in LEAGUE_DIVISIONS:
            players = await get_players_by_division(session, tier, division, player_count)
            results.extend(players)
    for tier in LEAGUE_TIERS_ELITE:
        players = await get_players_by_division(session, tier, 'I', player_count)
        results.extend(players)
    return results

async def get_players_distribution(session, distribution, player_count):
    players = []
    for d in distribution.iloc():
        count = int(np.ceil(d['percentage'] * player_count))
        players.extend(await get_players_by_division(session, d['tier'], d['division'], count))
    return players

async def get_players_from_division_range(session, tier_lower, division_lower, tier_upper, division_upper, count):
    players = []
    lower_tier_index = LEAGUE_TIERS.index(tier_lower)
    lower_division_index = LEAGUE_DIVISIONS.index(division_lower)
    upper_tier_index = LEAGUE_TIERS.index(tier_upper)
    upper_division_index = LEAGUE_DIVISIONS.index(division_upper)
    
    for ti in range(lower_tier_index, upper_tier_index + 1):
        for di in range(4):
            if di < lower_division_index and ti == lower_tier_index:
                continue
            if di > upper_division_index and ti == upper_tier_index:
                continue
            # With this commented, we'll collect 4x data for these ranks.
            # if tiers[ti] in ['MASTER', 'GRANDMASTER', 'CHALLENGER'] and di != divisions.index('I'):
            #     continue

            result = await get_players_by_division(session, LEAGUE_TIERS[ti], LEAGUE_DIVISIONS[di], count)
            players.extend(result)
    return players

#----------------------------------------------------------------------------------------
# getting data

async def get_match_ids_from_players(session, players, depth):
    tasks = [request_matches_from_puuid(session, p['puuid'], count=depth) for p in players]
    match_ids = []
    for coro in tqdm(asyncio.as_completed(tasks),
             total=len(tasks), 
             desc="Getting Match IDs  ",
             dynamic_ncols=True,
             leave=True):
        match_ids.extend(await coro)
    return match_ids

import json

async def save_match_data_from_ids(session, match_ids, path):
    tasks = [request_data_from_match_id(session, id) for id in match_ids]
    with open(path + "_matches.jsonl", "a", encoding="utf-8") as outfile:
        for task in tqdm(asyncio.as_completed(tasks),
                     total=len(tasks), 
                     desc="Getting Matches",
                     dynamic_ncols=True,
                     leave=False):
            data = await task
            outfile.write(json.dumps(data) + "\n")

async def save_timelines_from_ids(session, match_ids, path):
    tasks = [request_timeline_from_match_id(session, id) for id in match_ids]
    with open(path + "_timelines.jsonl", "a", encoding="utf-8") as outfile:
        for task in tqdm(asyncio.as_completed(tasks),
                          total=len(tasks),
                          desc="Getting Timelines",
                          dynamic_ncols=True,
                          leave=False):
            data = await task
            outfile.write(json.dumps(data) + "\n")

#-----------------------------------------------------------------------------------------------------

from helpers import clear_console, get_tier_division_lower_upper, get_tier_division, get_common_args, get_sampling_dt, log_runtime

async def main():
    sampling_type, data_type = get_sampling_dt()
            
    if sampling_type == 1: # Specific Division
        tier, division = get_tier_division()
    elif sampling_type == 3:
        tier_lower, division_lower, tier_upper, division_upper = get_tier_division_lower_upper()
    file_path, count, depth = get_common_args()
    
    clear_console()
    tqdm.write("Welcome to the match collector...")
    tqdm.write(f"Path: {file_path}.json | Player Count: {count} | Match Depth: {depth}")
    
    async with aiohttp.ClientSession() as session:
        start_time = time.time()
        if sampling_type == 1: # Specific Division
            tqdm.write(f"Matches: {count * depth} from {count} players @ {tier} {division}")
            players = await get_players_by_division(session, tier, division, count)
        elif sampling_type == 2: # All Divisions
            players = await get_players_from_all_divisions(session, count)
        elif sampling_type == 3:
            players = await get_players_from_division_range(session, tier_lower, division_lower, tier_upper, division_upper, count)
        elif sampling_type == 4: # Distribution
            players = await get_players_distribution(session, None, count)
        
        match_ids = await get_match_ids_from_players(session, players, depth)

        if data_type == 1: # Match Data
            await save_match_data_from_ids(session, match_ids, file_path)
        elif data_type == 2: # Timeline Data
            await save_timelines_from_ids(session, match_ids, file_path)
        elif data_type == 3: # Both
            await save_match_data_from_ids(session, match_ids, file_path)
            await save_timelines_from_ids(session, match_ids, file_path)
            
    log_runtime(start_time)

if __name__ == "__main__":
    asyncio.run(main())
