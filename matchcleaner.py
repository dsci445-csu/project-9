import pandas as pd

def mergeclean(timelines_path: str, matches_path:str):
    timelines_data = pd.read_json(timelines_path, lines = True)
    timelines_data = pd.DataFrame(timelines_data['info'].to_list())

    matches_data = pd.read_json(matches_path, lines = True)
    matches_data = pd.DataFrame(matches_data['info'].to_list())

    matches_data = matches_data.drop_duplicates(subset=['gameId'])

    df = matches_data.merge(timelines_data, on="gameId")

    df = df.drop(['gameCreation', 'gameMode', 'gameVersion', 'platformId', 'queueId', 
              'tournamentCode', 'gameModeMutators', 'frameInterval', 'mapId', 
              'gameType', 'gameStartTimestamp', 'gameEndTimestamp', 'gameName',
              'endOfGameResult_x', 'endOfGameResult_y'], axis=1)
    
    df = df[df['gameDuration'] > 900]

    return df

def unpack(df):
    """Returns: (performance, playstyle)"""
    rows =[]
    playstyle_rows = [] 

    for gameidx in range(len(df)):
        game = df.iloc[gameidx]
        for playeridx in range(10):
            pdata = game['participants_x'][playeridx]

            deaths = pdata['deaths']
            dragonKills = pdata['dragonKills']
            baronKills = pdata['baronKills']
            firstBloodKill = pdata['firstBloodKill']
            firstBloodAssist = pdata['firstBloodAssist']
            kills = pdata['kills']
            lane = pdata['lane']
            neutralMinionsKilled = pdata['neutralMinionsKilled']
            turretTakedowns = pdata['turretTakedowns']
            visionScore = pdata['visionScore']
            goldEarned = pdata['goldEarned']
            timeCCingOthers = pdata['timeCCingOthers']

            pdata = game['participants_x'][playeridx]
            holdPings = pdata['holdPings']
            pushPings = pdata['pushPings']
            allInPings = pdata['allInPings']
            basicPings = pdata['basicPings']
            dangerPings = pdata['dangerPings']
            commandPings = pdata['commandPings']
            getBackPings = pdata['getBackPings']
            omwPings = pdata['onMyWayPings']
            retreatPings = pdata['retreatPings']
            assistPings = pdata['assistMePings']
            needVisionPings = pdata['needVisionPings']
            enemyVisionPings = pdata['enemyVisionPings']
            enemyMissingPings = pdata['enemyMissingPings']
            clearedPings = pdata['visionClearedPings']

            totalPings = holdPings + pushPings + allInPings + basicPings + dangerPings + commandPings + getBackPings + omwPings + retreatPings + assistPings + needVisionPings + enemyVisionPings + enemyMissingPings + clearedPings
            wardsPlaced = pdata['wardsPlaced']
            wardsKilled = pdata['wardsKilled']
            detectorPlaced = pdata['detectorWardsPlaced']
            turretTakedowns = pdata['turretTakedowns']
            turretsLost = pdata['turretsLost']
            position = game['participants_x'][playeridx]['role']
            duration = game['gameDuration']
            champion = pdata['championName']

            win = game['participants_x'][playeridx]['win']
            
            rows.append({
                'deaths': deaths,
                'dragonKills': dragonKills,
                'baronKills': baronKills,
                'firstBloodKill': firstBloodKill,
                'firstBloodAssist': firstBloodAssist,
                'kills': kills,
                'lane': lane,
                'neutralMinionsKilled': neutralMinionsKilled,
                'turretTakedowns': turretTakedowns,
                'turretsLost': turretsLost,
                'visionScore': visionScore,
                'goldEarned': goldEarned,
                'timeCCingOthers': timeCCingOthers,

                'enemyMissingPings': enemyMissingPings,
                'clearedPings': clearedPings,
                'totalPings': totalPings,

                'wardsPlaced': wardsPlaced,
                'wardsKilled': wardsKilled,
                'detectorPlaced': detectorPlaced,

                'position': position,
                'duration': duration,
                'champion': champion,
                'win': win
            })

    return pd.DataFrame(rows)


if __name__ == "__main__":
    print("Running matchcleaner.py\n> Combines and cleans a pair of corresponding timelines and match data, outputting to a .csv\n> " \
        "For best usage, get data from `python ryan-collector.py` with return type = 'Both'")

    timelines_path = input("Enter path to timelines data (Press [ENTER] for default): ")
    matches_path = input("Enter path to matches data (Press [ENTER] for default): ")
    output_path = input("Enter output path (Press [ENTER] for default): ")

    if timelines_path == "":
        timelines_path = "data/d2_250_1_timelines.jsonl"
    if matches_path == "":
        matches_path = "data/d2_250_1_matches.jsonl"
    if output_path == "":
        output_path = "data/d2_250_performance"

    df = mergeclean(timelines_path, matches_path)
    df = unpack(df)
    df = df.drop(columns="champion")
    df.to_csv(output_path+".csv", index=False)
    print(f"output successfully to: {output_path}")