import json
from tqdm import tqdm
import time

LEAGUE_TIERS = ['IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'EMERALD', 'DIAMOND', 'MASTER', 'GRANDMASTER', 'CHALLENGER']
LEAGUE_TIERS_LOW = ['IRON', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'EMERALD', 'DIAMOND']
LEAGUE_DIVISIONS = ['IV', 'III', 'II', 'I']
LEAGUE_TIERS_ELITE = ['MASTER', 'GRANDMASTER', 'CHALLENGER']

def parse_match_data(match_data):
    return match_data
    return match_data['info']['participants']

def write_json_str(json, filename):
    with open(filename, 'w') as f:
        f.write(json)

def write_json_list(json_file, filename):
    with open(f"{filename}.json", "w", encoding="utf-8") as f:
        f.write(json.dumps(json_file, indent=2))

def log_runtime(start_time):
        total_time = time.time() - start_time
        hours = total_time // 3600
        mins = (total_time % 3600) // 60
        secs = total_time % 60
        tqdm.write(f"[INFO] Completed in: {hours:02.0f}h:{mins:02.0f}m:{secs:02.0f}s")

def clear_console():
    print("\033[H\033[2J", end="")
    print("\033[H\033[3J", end="")
    print("\033c", end="")
  
# -----------------------------------------------------------------------------------      
# Input
    
def get_common_args():
    while True:
        file_path = input("Enter output file path: ")
        if file_path:
            break
        else:
            print("Invalid file path. Please enter a valid file path.")

    while True:
        try:
            count = int(input("Enter number of players to sample: "))
            if count > 0:
                break
            else:
                print("Invalid count. Please enter a positive integer.")
        except ValueError:
            print("Invalid input. Please enter a valid integer.")

    while True:
        try:
            depth = int(input("Enter number of matches per player: "))
            if depth > 0:
                break
            else:
                print("Invalid depth. Please enter a positive integer.")
        except ValueError:
            print("Invalid input. Please enter a valid integer.")

    return file_path, count, depth

def get_tier_division():
    while True:
        tier = input("Enter tier: ").upper()
        if tier in LEAGUE_TIERS:
            break
        else:
            print("Invalid tier. Please enter a valid tier.")
    while True:
        if tier in LEAGUE_TIERS_ELITE:
            division = 'I'
            break
        division = input("Enter division (I, II, III, IV): ").upper()
        if division in LEAGUE_DIVISIONS:
            break
        else:
            print("Invalid division. Please enter a valid division.")
    return tier, division

def get_tier_division_lower_upper():
    while True:
        tier_lower = input("Enter lower bound tier (inclusive): ").upper()
        if tier_lower in LEAGUE_TIERS:
            break
        else:
            print("Invalid tier. Please enter a valid tier.")
    while True:
        if tier_lower in LEAGUE_TIERS_ELITE:
            division_lower = 'I'
            break
        division_lower = input("Enter lower bound tier (I, II, III, IV; inclusive): ").upper()
        if division_lower in LEAGUE_DIVISIONS:
            break
        else:
            print("Invalid division. Please enter a valid division.")
            
    while True:
        tier_upper = input("Enter upper bound tier (inclusive): ").upper()
        if tier_upper in LEAGUE_TIERS:
            break
        else:
            print("Invalid tier. Please enter a valid tier.")
    while True:
        if tier_upper in LEAGUE_TIERS_ELITE:
            division_upper = 'I'
            break
        division_upper = input("Enter upper bound tier (I, II, III, IV; inclusive): ").upper()
        if division_upper in LEAGUE_DIVISIONS:
            break
        else:
            print("Invalid division. Please enter a valid division.")
            
    return tier_lower, division_lower, tier_upper, division_upper

def get_sampling_dt():
    while True:
        sampling_type = input("Enter Sampling Type: \n 1: Specific Division \n 2: All Divisions \n 3: By Range\n 4: By Distribution\n Type (1, 2, 3, 4): ")
        if sampling_type in ['1', '2', '3', '4']:
            sampling_type = int(sampling_type)
            break
        else:
            print("Invalid")

    while True:
        data_type = input("Enter Data Type: \n 1: Match Data \n 2: Timeline Data\n 3: Both \n Type (1, 2, 3): ")
        if data_type in ['1', '2', '3']:
            data_type = int(data_type)
            break
        else:
            print("Invalid")
    return sampling_type, data_type