import asyncio
import aiohttp
import json
from requesturls import match_ids_url, timeline_url
from helpers import write_json_list

async def get_match_data(puuid, api_key, count):
    match_ids = await match_ids_url(puuid, api_key, count)
    async with aiohttp.ClientSession() as session:
     async with session.get(match_ids) as resp:
        match_ids = await resp.json()
         return match_ids

async def get_timeline_data(match_id, api_key):
    timeline_url = await timeline_url(match_ids[0], api_key)
    async with aiohttp.ClientSession() as session:
     async with session.get(timeline_url) as resp:
        timeline = await resp.json()
         return timeline

async def track_events(frames):
    # track meaningful events
    total_kills = 0
    elite_monster = 0
    turrets_destroyed = 0
    for frame in frames:
        for event in frame['events']:
          t = event['type']
          # add meaningful events
          if t == 'CHAMPION_KILL':
            total_kills+=1
          if t == 'ELITE_MONSTER_KILL':
            elite_monster+=1
          if t == 'BUILDING_KILL':
            turrets_destroyed+=1
          # add more events
    return total_kills, elite_monster, turrets_destroyed
    
async def test():
    match_data = await get_match_data(puuid, api_key, count)
    timeline_data = await get_timeline_data(match_id, api_key)
    
    frames = timeline_data['info']['frames']
    # info -> frames -> events -> timestamp
    if frames[-1]['timestamp'] < 15*60000: # filter games less than 15 minutes
      print("Skip matches less than 15 minutes")
    else:
      print(f"Total kills: {total_kills}")
      print(f"Total elite monsters killed: {elite_monster}")
      print(f"Total turrets destroyed: {turrets_destroyed}")
final = .run(test())
print(json.dumps(final,indent=2))          
      
