import asyncio
from keyqueue import KeyQueue
from requesturls import page_url, match_ids_url, match_url, timeline_url


MAX_CONCURRENT_REQUESTS = 5

queue = [i for i in range(10)]

async def main():
    """Requests and saves data from the riot api given user specifications."""
    queue: KeyQueue = KeyQueue()
    
    for i in range(10):
        queue.add(f"KEY_{i}")
    
    for i in range(30):
        print(await queue.get_next())


if __name__ == "__main__":
    asyncio.run(main())
