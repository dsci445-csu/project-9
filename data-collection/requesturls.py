LEAGUE_TIERS = ['IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'EMERALD', 'DIAMOND', 'MASTER', 'GRANDMASTER', 'CHALLENGER']
LEAGUE_TIERS_LOW = ['IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'EMERALD', 'DIAMOND']
LEAGUE_DIVISIONS = ['IV', 'III', 'II', 'I']
LEAGUE_TIERS_ELITE = ['MASTER', 'GRANDMASTER', 'CHALLENGER']
ACCESS_POINT = "https://americas.api.riotgames.com"
NA1_ACCESS_POINT = 'https://na1.api.riotgames.com'

async def page_url(tier: str, division: str, api_key: str, page: int) -> str:
    """Returns a request URL for the given page."""
    if tier in LEAGUE_TIERS_ELITE:
        return f"{NA1_ACCESS_POINT}/lol/league/v4/{tier.lower()}leagues/by-queue/RANKED_SOLO_5x5?api_key={api_key}"
    else:
        return f"{NA1_ACCESS_POINT}/lol/league/v4/entries/RANKED_SOLO_5x5/{tier}/{division}?page={page}&api_key={api_key}"

async def match_ids_url(puuid: str, api_key: str, count: int = 100) -> str:
    """Returns a request URL for matches played by the specified player."""
    return f"{ACCESS_POINT}/lol/match/v5/matches/by-puuid/{puuid}/ids?start=0&count={count}&api_key={api_key}"
    

async def match_url(match_id: str, api_key: str) -> str:
    """Returns a request URL for a specified match data."""
    return f"{ACCESS_POINT}/lol/match/v5/matches/{match_id}?api_key={api_key}"
    

async def timeline_url(match_id: str, api_key: str) -> str:
    """Returns a request URL for a specified timeline data."""
    return f"{ACCESS_POINT}/lol/match/v5/matches/{match_id}/timeline?api_key={api_key}"