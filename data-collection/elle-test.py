import asyncio
import aiohttp
import json
from requesturls import match_ids_url, timeline_url
from helpers import write_json_list

puuid = "puuid"
api_key = "api"
count = 1

async def get_match_data(puuid, api_key, count):
    match_ids = await match_ids_url(puuid, api_key, count)
    async with aiohttp.ClientSession() as session:
        async with session.get(match_ids) as resp:
            match_ids = await resp.json()
            if not match_ids:
                print("Error: trouble accessing match data")
                return None
            return match_ids

async def get_timeline_data(match_id, api_key):
    timel_url = await timeline_url(match_id, api_key)
    async with aiohttp.ClientSession() as session:
        async with session.get(timel_url) as resp:
            timeline = await resp.json()
            if not timeline:
                print("Error: trouble accessing timeline data")
                return None
            return timeline

async def track_events(frames):
    # track meaningful events
    total_kills = 0
    elite_monster = 0
    turrets_destroyed = 0
    minion_kill = 0
    items_purchased = 0
    # difference between items destroyed vs items sold?
    items_destroyed = 0
    items_sold = 0
    wards_placed = 0
    # track if they're not prioritizing leveling the right ability
    skill_level_up = 0
    # track if they're hitting key levels like 6, 12, 18, etc. at expected times
    level_up = 0
    for frame in frames:
        for event in frame['events']:
            t = event['type']
            # add meaningful events
            if t == 'CHAMPION_KILL':
                total_kills += 1
            if t == 'ELITE_MONSTER_KILL':
                elite_monster += 1
            if t == 'BUILDING_KILL':
                turrets_destroyed += 1
            if t == 'ITEM_PURCHASED':
                items_purchased += 1
            if t == 'ITEM_DESTROYED':
                items_destroyed += 1
            if t == 'ITEM_SOLD':
                items_sold += 1
            if t == 'WARD_PLACED':
                wards_placed += 1
            if t == 'SKILL_LEVEL_UP':
                skill_level_up += 1
            if t == 'LEVEL_UP':
                level_up += 1
    return total_kills, elite_monster, turrets_destroyed, items_purchased, items_destroyed, items_sold, wards_placed, skill_level_up, level_up
    
async def test():
    match_data = await get_match_data(puuid, api_key, count)
    if not match_data:
        print("Error: no match data found")
    match_id = match_data[0]
    timeline_data = await get_timeline_data(match_id, api_key)
    frames = timeline_data['info']['frames']
    # info -> frames -> events -> timestamp
    if frames[-1]['timestamp'] < 15 * 60000: # filter games less than 15 minutes
      print("Skip matches less than 15 minutes")
      return None
    else:
      # call track_events with frames to print events
      total_kills, elite_monster, turrets_destroyed, items_purchased, items_destroyed,items_sold, wards_placed, skill_level_up, level_up = await track_events(frames)
      print(f"Total kills: {total_kills}")
      print(f"Total elite monsters killed: {elite_monster}")
      print(f"Total turrets destroyed: {turrets_destroyed}")
      print(f"Items purchased: {items_purchased}")
      print(f"Items destroyed: {items_destroyed}")
      print(f"Items sold: {items_sold}")
      print(f"Wards placed: {wards_placed}")
      print(f"Skill level up: {skill_level_up}")
      print(f"Total level ups: {level_up}")
final = asyncio.run(test())
print(json.dumps(final, indent = 2))     
      
