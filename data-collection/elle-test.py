import asyncio
from requesturls import match_ids_url, timeline_url

puuid = "your puuid here"
count = 10 # num of most recent games

async def main():
  players = [{'puuid' : puuid}]
  # only grabs urls not data yet
  match_ids = await match_ids_url(None, players, count)
  timeline = await timeline_url(None, match_ids)
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
        type = event['type']
        # add meaningful events
        if type == 'CHAMPION_KILL':
          total_kills+=1
        if type == 'ELITE_MONSTER_KILL':
          elite_monster+=1
        if type == 'BUILDING_KILL':
          turrets_destroyed+=1
          
      
