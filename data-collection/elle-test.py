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
  # filter games less than 15 minutes == 900 seconds
  # info -> frames -> events -> timestamp
  if frames[-1]['timestamp'] < 15*60000:
    print("Skip matches less than 15 minutes")
    continue;
