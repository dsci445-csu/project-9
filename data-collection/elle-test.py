import asyncio
from requesturls import match_ids_url, timeline_url

puuid = "your puuid here"
count = 10

async def main():
  players = [{'puuid' : puuid}]
  match_ids = match_ids_url(None, players, count)
  timeline = timeline_url(None, match_ids)
  frames = timeline['InfoTimeLineDto']['frames']
  # filter games less than 15 minutes == 900 seconds
  if frames['timestamp'] < 15*60000:
    print("Skip matches less than 15 minutes")
    continue;
