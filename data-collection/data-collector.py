import asyncio
from requesturls import page_url, match_ids_url, match_url, timeline_url

RATE_LIMIT = 100
WINDOW = 120  # seconds
REQUEST_INTERVAL = WINDOW / RATE_LIMIT  # 1.2s (for 100 requests per 2 minutes)
MAX_CONCURRENT_REQUESTS = 5

queue = [i for i in range(10)]

async def test():

    while(queue):
        print(queue.pop())
        await asyncio.sleep(1)


# two main modules
# 1) key manager module: ensures valid keys
# 1.5) interface between
# 2) requester module: uses interface to grab keys and then uses them to get data



if __name__ == "__main__":
    asyncio.run(test())
