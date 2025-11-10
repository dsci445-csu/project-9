import asyncio
import aiohttp
import json
from requesturls import match_ids_url, timeline_url
from helpers import write_json_list

puuid = "puuid here"
api_key = "api key here"
count = 1 # num of most recent games

async def test():
    match_ids = await match_ids_url(puuid, api_key, count)
    async with aiohttp.ClientSession() as session:
     async with session.get(match_ids) as resp:
        match_ids = await resp.json()
    timel = await timeline_url(match_ids[0], api_key)
    async with aiohttp.ClientSession() as session:
     async with session.get(timel) as resp:
        timeline = await resp.json()
    frames = timeline['info']['frames']
    # info -> frames -> events -> timestamp
    if frames[-1]['timestamp'] < 15*60000: # filter games less than 15 minutes
      print("Skip matches less than 15 minutes")
    else: # valid match
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
          # minions killed, player gold over time
      print(f"Total kills: {total_kills}")
      print(f"Total elite monsters killed: {elite_monster}")
      print(f"Total turrets destroyed: {turrets_destroyed}")
final=asyncio.run(test())
print(json.dumps(final,indent=2))          
      
